import Product from "@/models/Product";
import dbConnect from "@/lib/db";

export async function GET() {
  try {
    await dbConnect();
    const products = await Product.find().populate('category');
    return Response.json(products);
  } catch (error) {
    console.error('GET /api/product error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch products' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function POST(request) {
  try {
    await dbConnect();
    const body = await request.json();
    console.log('POST body:', body)
    const product = new Product(body);
    await product.save();
    return Response.json(product);
  } catch (error) {
    console.error('POST /api/product error:', error);
    return new Response(JSON.stringify({ error: 'Failed to create product' }), { 
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
    const product = await Product.findByIdAndUpdate(_id, updateData, { new: true });
    if (!product) {
      return new Response(JSON.stringify({ error: 'Product not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    return Response.json(product);
  } catch (error) {
    console.error('PUT /api/product error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update product' }), { 
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
    const product = await Product.findByIdAndUpdate(_id, updateData, { new: true });
    if (!product) {
      return new Response(JSON.stringify({ error: 'Product not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    return Response.json(product);
  } catch (error) {
    console.error('PATCH /api/product error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update product' }), { 
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
      return new Response(JSON.stringify({ error: 'Product ID is required' }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const product = await Product.findByIdAndDelete(id);
    if (!product) {
      return new Response(JSON.stringify({ error: 'Product not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return Response.json({ message: 'Product deleted successfully', product });
  } catch (error) {
    console.error('DELETE /api/product error:', error);
    return new Response(JSON.stringify({ error: 'Failed to delete product' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}