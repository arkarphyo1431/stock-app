import mongoose from "mongoose";

const customerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  dateOfBirth: { type: Date, required: true },
  memberNumber: { 
    type: Number, 
    required: true,
    enum: [1, 2, 3, 4]
  },
  interests: { type: String, required: true }
});

const Customer = mongoose.models.customer || mongoose.model("customer", customerSchema);

export default Customer;