import { redirect, error } from "@sveltejs/kit";
import type { PageServerLoad } from "./$types";
import { Firestore } from "@google-cloud/firestore";
import { env } from "$env/dynamic/private";

export const load: PageServerLoad = async ({ locals, params }) => {
  if (!locals.session)
    throw redirect(302, `/login?returnTo=/uploads/${params.id}`);
  const db = new Firestore({
    projectId: env.GCP_PROJECT_ID,
    databaseId: env.FIRESTORE_DATABASE_ID ?? "(default)",
  });
  const doc = await db.collection("uploads").doc(params.id).get();
  if (!doc.exists) throw error(404, "Upload not found");
  const data = doc.data()!;
  if (data.userId !== locals.session.user.id) throw error(403, "Forbidden");
  return {
    upload: {
      id: doc.id,
      cdnBasePath: data.cdnBasePath as string,
      filename: data.filename as string,
      purpose: data.purpose as string,
      uploadedAt: (data.uploadedAt as FirebaseFirestore.Timestamp)
        .toDate()
        .toISOString(),
    },
  };
};
