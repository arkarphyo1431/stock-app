import Customer from "@/models/Customer";
import dbConnect from "@/lib/db";

export async function GET(request, { params }) {
  try {
    await dbConnect();
    console.log(params);
    const id = params.id;
    const customer = await Customer.findById(id);
    console.log({ customer });
    
    if (!customer) {
      return new Response(JSON.stringify({ error: 'Customer not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return Response.json(customer);
  } catch (error) {
    console.error('GET /api/customer/[id] error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch customer' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function PUT(request, { params }) {
  try {
    await dbConnect();
    const id = params.id;
    const body = await request.json();
    
    const customer = await Customer.findByIdAndUpdate(id, body, { new: true });
    
    if (!customer) {
      return new Response(JSON.stringify({ error: 'Customer not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return Response.json(customer);
  } catch (error) {
    console.error('PUT /api/customer/[id] error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update customer' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function DELETE(request, { params }) {
  try {
    await dbConnect();
    const id = params.id;
    const customer = await Customer.findByIdAndDelete(id);
    
    if (!customer) {
      return new Response(JSON.stringify({ error: 'Customer not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return Response.json({ message: 'Customer deleted successfully', customer });
  } catch (error) {
    console.error('DELETE /api/customer/[id] error:', error);
    return new Response(JSON.stringify({ error: 'Failed to delete customer' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}