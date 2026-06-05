# Firebase Storage image access notes

Flutter Web reports `HTTP request failed, statusCode: 0` when the browser cannot expose the Storage response to the app. In this project, image uploads already write a Firebase Storage download URL to `shops.imageUrl`, so the most likely external setting to verify is the bucket CORS configuration.

Apply the included CORS policy to the production bucket from an authenticated Google Cloud environment:

```bash
gcloud storage buckets update gs://salon-note.firebasestorage.app --cors-file=storage.cors.json
```

After applying it, verify the direct download URL in a browser and confirm the web app logs the same bucket as Firebase Console.
