import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

// Interface payload nhận từ Database Webhook hoặc Client gọi trực tiếp
interface PushNotificationPayload {
  family_id: string;
  target_role?: "parent" | "child" | "all";
  target_member_id?: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

// Lấy Access Token từ Google OAuth2 Service Account
async function getGoogleAccessToken(serviceAccount: Record<string, any>): Promise<string> {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: exp,
    iat: iat,
  };

  const encodeBase64Url = (obj: any) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const unsignedJwt = `${encodeBase64Url(header)}.${encodeBase64Url(claimSet)}`;

  // Parse RSA Private Key
  const pem = serviceAccount.private_key;
  const binaryDerString = atob(
    pem
      .replace(/-----BEGIN PRIVATE KEY-----/, "")
      .replace(/-----END PRIVATE KEY-----/, "")
      .replace(/\s+/g, "")
  );
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedJwt)
  );

  const signedJwt = `${unsignedJwt}.${btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${signedJwt}`,
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const payload: PushNotificationPayload = await req.json();
    const { family_id, target_role, target_member_id, title, body, data } = payload;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

    if (!serviceAccountJson) {
      throw new Error("Missing FIREBASE_SERVICE_ACCOUNT in Supabase secrets");
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Tìm các device tokens phù hợp
    let query = supabase
      .from("device_tokens")
      .select("fcm_token, member_id, members!inner(role)")
      .eq("family_id", family_id);

    if (target_member_id) {
      query = query.eq("member_id", target_member_id);
    } else if (target_role && target_role !== "all") {
      query = query.eq("members.role", target_role);
    }

    const { data: tokens, error: dbError } = await query;
    if (dbError) throw dbError;
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No target tokens found" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Lấy Access Token FCM v1
    const accessToken = await getGoogleAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id;
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // 3. Gửi thông báo tới từng thiết bị
    const sendPromises = tokens.map(async (row: any) => {
      const message = {
        message: {
          token: row.fcm_token,
          notification: {
            title: title,
            body: body,
          },
          data: data || {},
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channel_id: "beong_notifications",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        },
      };

      const res = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      });

      return res.json();
    });

    const results = await Promise.all(sendPromises);

    return new Response(JSON.stringify({ success: true, count: results.length, results }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
