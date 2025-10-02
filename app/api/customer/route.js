import Customer from "@/models/Customer";
import dbConnect from "@/lib/db";

export async function GET() {
  try {
    await dbConnect();
    const customers = await Customer.find();
    return Response.json(customers);
  } catch (error) {
    console.error('GET /api/customer error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch customers' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function POST(request) {
  try {
    await dbConnect();
    const body = await request.json();
    console.log('POST body:', body);
    const customer = new Customer(body);
    await customer.save();
    return Response.json(customer);
  } catch (error) {
    console.error('POST /api/customer error:', error);
    return new Response(JSON.stringify({ error: 'Failed to create customer' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function PUT(request) {
  try {
    await dbConnect();
    const body = await request.json();
    const { _id, ...updateData } = body;
    const customer = await Customer.findByIdAndUpdate(_id, updateData, { new: true });
    if (!customer) {
      return new Response(JSON.stringify({ error: 'Customer not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    return Response.json(customer);
  } catch (error) {
    console.error('PUT /api/customer error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update customer' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function PATCH(request) {
  try {
    await dbConnect();
    const body = await request.json();
    const { _id, ...updateData } = body;
    const customer = await Customer.findByIdAndUpdate(_id, updateData, { new: true });
    if (!customer) {
      return new Response(JSON.stringify({ error: 'Customer not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    return Response.json(customer);
  } catch (error) {
    console.error('PATCH /api/customer error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update customer' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function DELETE(request) {
  try {
    await dbConnect();
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    
    if (!id) {
      return new Response(JSON.stringify({ error: 'Customer ID is required' }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const customer = await Customer.findByIdAndDelete(id);
    if (!customer) {
      return new Response(JSON.stringify({ error: 'Customer not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return Response.json({ message: 'Customer deleted successfully', customer });
  } catch (error) {
    console.error('DELETE /api/customer error:', error);
    return new Response(JSON.stringify({ error: 'Failed to delete customer' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}