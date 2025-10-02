import Customer from "@/models/Customer";

export async function GET(request, { params }) {
  console.log(params);
  const id = params.id;
  const customer = await Customer.findById(id);
  console.log({ customer });
  return Response.json(customer);
}

export async function DELETE(request, { params }) {
  const id = params.id;
  return Response.json(await Customer.findByIdAndDelete(id));
}