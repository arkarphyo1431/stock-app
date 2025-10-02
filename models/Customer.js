import mongoose from "mongoose";

const customerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  dateOfBirth: { type: Date, required: true },
  memberNumber: { 
    type: String, 
    required: true,
    unique: true
  },
  interests: [String]
}, { collection: 'Customer' });

const Customer = mongoose.models.Customer || mongoose.model("Customer", customerSchema);

export default Customer;