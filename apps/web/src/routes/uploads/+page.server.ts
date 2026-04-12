import { redirect, error } from "@sveltejs/kit";
import type { PageServerLoad } from "./$types";
import { Firestore } from "@google-cloud/firestore";
import { env } from "$env/dynamic/private";

export const load: PageServerLoad = async ({ locals }) => {
  if (!locals.session) throw redirect(302, "/login?returnTo=/uploads");
  const db = new Firestore({
    projectId: env.GCP_PROJECT_ID,
    databaseId: env.FIRESTORE_DATABASE_ID ?? "(default)",
  });
  try {
    const snap = await db
      .collection("uploads")
      .where("userId", "==", locals.session.user.id)
      .orderBy("uploadedAt", "desc")
      .limit(50)
      .get();
    return {
      uploads: snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          cdnBasePath: data.cdnBasePath as string,
          filename: data.filename as string,
          uploadedAt: (data.uploadedAt as FirebaseFirestore.Timestamp)
            .toDate()
            .toISOString(),
        };
      }),
    };
  } catch (err) {
    console.error(err);
    throw error(500, "Failed to load uploads");
  }
};
