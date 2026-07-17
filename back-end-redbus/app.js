const express = require("express");
const app = express();
const mongoose = require("mongoose");
const cors = require("cors");
const { v4: uuidv4 } = require("uuid");

// Initialize Stripe - key must be set via STRIPE_SECRET_KEY environment variable
const stripeKey = process.env.STRIPE_SECRET_KEY;
if (!stripeKey) {
  console.warn("Warning: STRIPE_SECRET_KEY environment variable not set");
}
const stripe = require("stripe")(stripeKey || "sk_test_placeholder");

mongoose.pluralize(null);
app.use(express.json());
app.use(cors());

// Health check endpoint for Kubernetes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

const busRoutes = require("./routes/bus");
const bookingRoutes = require("./routes/booking");
const customerRoutes = require("./routes/customer");
const routeRoutes = require("./routes/route");

app.post("/v1/api/stripe-payments", async (req, res) => {
  const { product, token } = req.body;
  console.log("PRODUCT", product);
  console.log("PRICE", product.price);
  const idempontencyKey = uuidv4();
  return stripe.customers
    .create({
      email: token.email,
      source: token.id,
    })
    .then((customer) => {
      stripe.charges.create(
        {
          amount: product.price * 100,
          currency: "inr",
          customer: customer.id,
          receipt_email: token.email,
          description: `Purchase of ${product.name}`,
        },
        { idempontencyKey }
      );
    })
    .then((result) => res.status(200).json(result))
    .catch((err) => console.log(err));
});

app.use(busRoutes);
app.use(bookingRoutes);
app.use(customerRoutes);
app.use(routeRoutes);
const bookingHireRoutes = require("./routes/bookinghire");
app.use(bookingHireRoutes);

const busServiceRoutes = require("./routes/busservice");
app.use(busServiceRoutes);

const connect = () => {
  const db = mongoose.connection; // Get the mongoose connection object

  // Listen to events on the mongoose connection
  db.on('error', (error) => {
    console.error('MongoDB connection error:', error);
  });

  db.once('open', () => {
    console.log('MongoDB connection established.');
  });

  // Use MONGODB_URI from environment (must be set via .env or config.env)
  const mongoUri = process.env.MONGODB_URI;
  if (!mongoUri) {
    throw new Error("MONGODB_URI environment variable is not set. Please configure it in config.env or your environment.");
  }

  return mongoose.connect(mongoUri);
};


const port = process.env.PORT || 5000;
let host = process.env.HOST;

const start = async () => {
  await connect().then(() => console.log("Database connected")).catch((err) => console.log(err));
  app.listen(port, host, () => console.log("Server is running"));
};
start();
