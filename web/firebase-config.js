// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";
import { getDatabase } from "firebase/database";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyC5Qctjwcs780mH1YB79BrpYRzEP30AYKM",
  authDomain: "agroflow-8227b.firebaseapp.com",
  databaseURL: "https://agroflow-8227b-default-rtdb.firebaseio.com",
  projectId: "agroflow-8227b",
  storageBucket: "agroflow-8227b.firebasestorage.app",
  messagingSenderId: "819492784366",
  appId: "1:819492784366:web:455931686819eec58e0bff"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);
export const database = getDatabase(app);

export default app;