import mongoose from "mongoose";

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  price: { type: Number, required: true },
  category: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "Category" 
  },
  inStock: { type: Boolean, default: true }
}, { collection: 'product' });

const Product = mongoose.models.Product || mongoose.model("Product", productSchema);

export default Product;
