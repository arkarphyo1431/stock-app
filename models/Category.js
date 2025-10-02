import mongoose from "mongoose";

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  description: String,
  order: Number
}, { collection: 'category' });

const Category = mongoose.models.Category || mongoose.model("Category", categorySchema);

export default Category;
