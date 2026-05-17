const express = require("express");
const axios = require("axios");
const CryptoJS = require("crypto-js");
const cors = require("cors");
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

const app = express();
app.use(express.json());
app.use(cors());

const CONFIG = {
  partnerCode: "MOMO",
  accessKey: "F8BBA842ECF85",
  secretKey: "K951B6PE1waDMi640xX08PD3vg6EkVlz",
  endpoint: "https://test-payment.momo.vn/v2/gateway/api/create",
};

app.post("/create-momo-payment", async (req, res) => {
  try {
    const { amount, orderId, userId } = req.body;
    if (!amount || !orderId || !userId) {
      return res.status(400).json({ error: "Thiếu dữ liệu" });
    }

    const requestId = orderId + "_" + Date.now();
    const orderInfo = "Nap Tien RAINN Services";
    const redirectUrl = "rainn://payment-result";
    const ipnUrl = "https://anew-android-batboy.ngrok-free.dev/momo-ipn"; // CẬP NHẬT LINK NGROK MỚI TẠI ĐÂY
    const requestType = "payWithATM";
    const extraData = Buffer.from(JSON.stringify({ userId })).toString(
      "base64",
    );

    const rawSignature = `accessKey=${CONFIG.accessKey}&amount=${amount}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${CONFIG.partnerCode}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;
    const signature = CryptoJS.HmacSHA256(
      rawSignature,
      CONFIG.secretKey,
    ).toString(CryptoJS.enc.Hex);

    const body = {
      partnerCode: CONFIG.partnerCode,
      accessKey: CONFIG.accessKey,
      requestId,
      amount: Number(amount),
      orderId,
      orderInfo,
      redirectUrl,
      ipnUrl,
      extraData,
      requestType,
      signature,
      lang: "vi",
    };

    const response = await axios.post(CONFIG.endpoint, body);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: "Lỗi kết nối MoMo" });
  }
});

app.post("/momo-ipn", async (req, res) => {
  console.log("📩 IPN nhận được:", JSON.stringify(req.body, null, 2));

  const { amount, resultCode, extraData, orderId } = req.body;

  if (resultCode === 0) {
    try {
      const decoded = Buffer.from(
        decodeURIComponent(extraData),
        "base64"
      ).toString("utf-8");

      console.log("🔍 extraData decoded:", decoded);

      const parsed = JSON.parse(decoded);
      const userId = parsed.userId;

      if (!userId) {
        console.error("❌ userId rỗng sau khi decode!");
        return res.status(204).send();
      }

      console.log(`💰 Cộng ${amount}đ cho userId: ${userId}`);

      await db.collection("users").doc(userId).set(
        {
          balance: admin.firestore.FieldValue.increment(Number(amount)),
          lastDeposit: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await db.collection("transactions").add({
        userId,
        amount: Number(amount),
        type: "deposit",
        orderId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Đã cộng ${amount}đ cho ${userId}`);
    } catch (e) {
      console.error("❌ Lỗi IPN:", e);
    }
  }

  res.status(204).send();
});

app.listen(3000, () => console.log("🚀 Server chạy tại port 3000"));
