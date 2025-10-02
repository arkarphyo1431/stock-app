import Category from "@/models/Category";
import dbConnect from "@/lib/db";

export async function GET(request) {
  try {
    await dbConnect();
    // console.log('GET /api/category',request.nextUrl.searchParams.get("pno"))
    const pno = request.nextUrl.searchParams.get("pno")
    if (pno) {
      const size = 3 // TODO fix this hard code
      const startIndex = (pno - 1) * size
      const categories = await Category.find()
        .sort({ order: -1 })
        .skip(startIndex)
        .limit(size)
      return Response.json(categories)
    }

    const s = request.nextUrl.searchParams.get("s")
    if (s) {
      const categories = await Category
        .find({ name: { $regex: s, $options: 'i' } })
        .sort({ order: -1 })
      return Response.json(categories)
    }

    const categories = await Category.find().sort({ order: -1 })
    return Response.json(categories)
  } catch (error) {
    console.error('GET /api/category error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch categories' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function POST(request) {
  try {
    await dbConnect();
    const body = await request.json()
    const category = new Category(body)
    await category.save()
    return Response.json(category)
  } catch (error) {
    console.error('POST /api/category error:', error);
    return new Response(JSON.stringify({ error: 'Failed to create category' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// for V2
export async function PUT(request) {
  try {
    await dbConnect();
    const body = await request.json()
    const category = await Category.findByIdAndUpdate(body._id, body, { new: true })
    if (!category) {
      return new Response(JSON.stringify({ error: 'Category not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    return Response.json(category)
  } catch (error) {
    console.error('PUT /api/category error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update category' }), { 
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
      return new Response(JSON.stringify({ error: 'Category ID is required' }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const category = await Category.findByIdAndDelete(id);
    if (!category) {
      return new Response(JSON.stringify({ error: 'Category not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return Response.json({ message: 'Category deleted successfully', category });
  } catch (error) {
    console.error('DELETE /api/category error:', error);
    return new Response(JSON.stringify({ error: 'Failed to delete category' }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}