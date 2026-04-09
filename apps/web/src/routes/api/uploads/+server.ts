import { json, error } from "@sveltejs/kit";
import type { RequestHandler } from "./$types";
import { Firestore } from "@google-cloud/firestore";
import { env } from "$env/dynamic/private";

function getDb() {
  return new Firestore({
    projectId: env.GCP_PROJECT_ID,
    databaseId: env.FIRESTORE_DATABASE_ID ?? "(default)",
  });
}

export const POST: RequestHandler = async ({ request, locals }) => {
  if (!locals.session?.user?.id) throw error(401, "Unauthorized");
  const { basePath, cdnBasePath, srcset, original, purpose, filename } =
    await request.json();
  if (!basePath || !cdnBasePath) throw error(400, "Missing required fields");

  const db = getDb();
  const ref = db.collection("uploads").doc();
  await ref.set({
    id: ref.id,
    userId: locals.session.user.id,
    basePath,
    cdnBasePath,
    srcset,
    original: original ?? null,
    purpose: purpose ?? "general",
    filename: filename ?? "upload",
    uploadedAt: new Date(),
  });
  return json({ id: ref.id });
};

export const GET: RequestHandler = async ({ locals }) => {
  if (!locals.session?.user?.id) throw error(401, "Unauthorized");
  const snapshot = await getDb()
    .collection("uploads")
    .where("userId", "==", locals.session.user.id)
    .orderBy("uploadedAt", "desc")
    .limit(50)
    .get();
  return json({
    uploads: snapshot.docs.map((d) => ({ id: d.id, ...d.data() })),
  });
};
