import { useState, type ChangeEvent, useEffect } from "react";
import {
  S3Client,
  CreateBucketCommand,
  PutObjectCommand,
  ListBucketsCommand,
  HeadObjectCommand,
  ListObjectsV2Command,
} from "@aws-sdk/client-s3";
import { Upload } from "@aws-sdk/lib-storage";

const REGION = import.meta.env.VITE_S3_REGION || "us-east-1";
const ENDPOINT = import.meta.env.VITE_S3_ENDPOINT || "http://localhost:9000";
const ACCESS_KEY = import.meta.env.VITE_S3_ACCESS_KEY || "minio";
const SECRET_KEY = import.meta.env.VITE_S3_SECRET_KEY || "password";

const s3Client = new S3Client({
  region: REGION,
  endpoint: ENDPOINT,
  credentials: {
    accessKeyId: ACCESS_KEY,
    secretAccessKey: SECRET_KEY,
  },
  forcePathStyle: true, // obligatoire pour MinIO
});

export default function MinioManager() {
  const [file, setFile] = useState<File | null>(null);
  const [iiifUrl, setIiifUrl] = useState<string>("");
  const [error, setError] = useState<string | null>(null);

  const [bucketName, setBucketName] = useState<string>("");
  const [newBucketName, setNewBucketName] = useState<string>("");

  const [folderName, setFolderName] = useState<string>("");
  const [selectedBucket, setSelectedBucket] = useState<string>("");
  const [buckets, setBuckets] = useState<string[]>([]);

  // Liste les buckets au chargement
  useEffect(() => {
    async function fetchBuckets() {
      try {
        const res = await s3Client.send(new ListBucketsCommand({}));
        if (res.Buckets) {
          const names = res.Buckets.map((b) => b.Name!).filter(Boolean);
          setBuckets(names);
          if (names.length > 0) setSelectedBucket(names[0]);
        }
      } catch (e: any) {
        setError("Erreur liste buckets : " + e.message);
      }
    }
    fetchBuckets();
  }, []);

  // Gestion input file
  const handleFileChange = (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0]);
      setIiifUrl("");
      setError(null);
    }
  };

  // Vérifier si fichier existe
  async function checkIfFileExists(fileName: string): Promise<boolean> {
    try {
      await s3Client.send(
        new HeadObjectCommand({ Bucket: selectedBucket, Key: fileName })
      );
      return true;
    } catch (err: any) {
      if (err.name === "NotFound" || err.$metadata?.httpStatusCode === 404) {
        return false;
      }
      throw err;
    }
  }

  // Upload fichier
  const handleUpload = async () => {
    if (!file) return;
    setError(null);

    try {
      if (!selectedBucket) {
        alert("Merci de sélectionner un bucket !");
        return;
      }
      const exists = await checkIfFileExists(file.name);
      let fileToUpload = file;

      if (exists) {
        const rename = window.confirm(
          "Le fichier existe déjà, veux-tu changer le nom ?"
        );
        if (!rename) return;

        const newName = window.prompt("Nouveau nom de fichier ?", file.name);
        if (!newName) return;
        fileToUpload = new File([file], newName, { type: file.type });
      }

      const upload = new Upload({
        client: s3Client,
        params: {
          Bucket: selectedBucket,
          Key: fileToUpload.name,
          Body: fileToUpload,
          ContentType: fileToUpload.type,
        },
      });

      await upload.done();

      const url = `http://localhost:8182/iiif/2/${fileToUpload.name}/full/full/0/default.jpg`;
      setIiifUrl(url);
    } catch (err: any) {
      setError("Erreur upload: " + (err.message || err.toString()));
    }
  };

  // Création bucket
  const handleCreateBucket = async () => {
    if (!newBucketName) {
      alert("Merci de saisir un nom de bucket.");
      return;
    }
    setError(null);
    try {
      await s3Client.send(
        new CreateBucketCommand({ Bucket: newBucketName.toLowerCase() })
      );
      setBuckets((prev) => [...prev, newBucketName.toLowerCase()]);
      setSelectedBucket(newBucketName.toLowerCase());
      setNewBucketName("");
    } catch (err: any) {
      setError("Erreur création bucket : " + (err.message || err.toString()));
    }
  };

  // Création "dossier"
  const handleCreateFolder = async () => {
    if (!selectedBucket) {
      alert("Merci de sélectionner un bucket.");
      return;
    }
    if (!folderName) {
      alert("Merci de saisir un nom de dossier.");
      return;
    }
    setError(null);
    try {
      // Un "dossier" est un objet vide dont la clé finit par /
      await s3Client.send(
        new PutObjectCommand({
          Bucket: selectedBucket,
          Key: folderName.endsWith("/") ? folderName : folderName + "/",
          Body: "",
        })
      );
      setFolderName("");
      alert(`Dossier '${folderName}' créé dans le bucket '${selectedBucket}'`);
    } catch (err: any) {
      setError("Erreur création dossier : " + (err.message || err.toString()));
    }
  };

  return (
    <div style={{ padding: 20, maxWidth: 700 }}>
      <h2>Uploader une image vers MinIO</h2>
      <div style={{ marginBottom: 10 }}>
        <label>
          Bucket actuel :{" "}
          <select
            value={selectedBucket}
            onChange={(e) => setSelectedBucket(e.target.value)}
          >
            {buckets.map((b) => (
              <option key={b} value={b}>
                {b}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div style={{ marginBottom: 10 }}>
        <input type="file" accept="image/*" onChange={handleFileChange} />
        <button
          onClick={handleUpload}
          disabled={!file || !selectedBucket}
          style={{ marginLeft: 10 }}
        >
          Upload
        </button>
      </div>
      {iiifUrl && (
        <div style={{ marginTop: 10 }}>
          <p>Image IIIF :</p>
          <a href={iiifUrl} target="_blank" rel="noopener noreferrer">
            {iiifUrl}
          </a>
          <div style={{ marginTop: 10 }}>
            <img src={iiifUrl} alt="Preview" width={400} />
          </div>
        </div>
      )}
      <hr />
      <div>
        <h3>Créer un nouveau bucket</h3>
        <input
          placeholder="Nom du bucket"
          value={newBucketName}
          onChange={(e) => setNewBucketName(e.target.value)}
        />
        <button onClick={handleCreateBucket} style={{ marginLeft: 10 }}>
          Créer bucket
        </button>
      </div>
      <div style={{ marginTop: 20 }}>
        <h3>Créer un dossier dans le bucket sélectionné</h3>
        <input
          placeholder="Nom du dossier"
          value={folderName}
          onChange={(e) => setFolderName(e.target.value)}
        />
        <button onClick={handleCreateFolder} style={{ marginLeft: 10 }}>
          Créer dossier
        </button>
      </div>
      {error && (
        <div style={{ marginTop: 20, color: "red" }}>
          <strong>Erreur:</strong> {error}
        </div>
      )}
    </div>
  );
}
