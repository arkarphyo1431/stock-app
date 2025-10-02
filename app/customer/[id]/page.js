'use client';
import Link from 'next/link';
import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/fin-customer';

export default function CustomerDetailPage() {
  const [customer, setCustomer] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const params = useParams();

  useEffect(() => {
    const fetchCustomer = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/api/customer/${params.id}`);
        if (response.ok) {
          const data = await response.json();
          setCustomer(data);
        } else {
          setError('Customer not found');
        }
      } catch (error) {
        console.error('Error fetching customer:', error);
        setError('Failed to load customer details');
      } finally {
        setLoading(false);
      }
    };

    if (params.id) {
      fetchCustomer();
    }
  }, [params.id]);

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const getMemberTierInfo = (memberNumber) => {
    const tiers = {
      1: { 
        label: 'Bronze', 
        color: 'bg-amber-100 text-amber-800 border-amber-200',
        description: 'Basic membership with standard benefits'
      },
      2: { 
        label: 'Silver', 
        color: 'bg-gray-100 text-gray-800 border-gray-200',
        description: 'Standard membership with enhanced benefits'
      },
      3: { 
        label: 'Gold', 
        color: 'bg-yellow-100 text-yellow-800 border-yellow-200',
        description: 'Premium membership with exclusive benefits'
      },
      4: { 
        label: 'Platinum', 
        color: 'bg-purple-100 text-purple-800 border-purple-200',
        description: 'Elite membership with all premium benefits'
      }
    };
    return tiers[memberNumber] || { 
      label: 'Unknown', 
      color: 'bg-gray-100 text-gray-800 border-gray-200',
      description: 'Membership tier not recognized'
    };
  };

  const calculateAge = (dateOfBirth) => {
    const today = new Date();
    const birthDate = new Date(dateOfBirth);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading customer details...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 mx-auto mb-4 bg-red-100 rounded-full flex items-center justify-center">
            <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">Error Loading Customer</h3>
          <p className="text-gray-500 mb-4">{error}</p>
          <Link
            href="/customer"
            className="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors"
          >
            ← Back to Customers
          </Link>
        </div>
      </div>
    );
  }

  if (!customer) {
    return null;
  }

  const tierInfo = getMemberTierInfo(customer.memberNumber);
  const age = calculateAge(customer.dateOfBirth);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Customer Details</h1>
              <p className="mt-1 text-sm text-gray-500">View customer information and profile</p>
            </div>
            <div className="flex space-x-3">
              <Link 
                href="/fin-customer/customer"
                className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 transition-colors"
              >
                ← Back to Customers
              </Link>
              <Link
                href={`/fin-customer/customer/edit/${customer._id}`}
                className="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors"
              >
                Edit Customer
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Customer Profile */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
          {/* Profile Header */}
          <div className="bg-gradient-to-r from-blue-500 to-blue-600 px-6 py-8">
            <div className="flex items-center space-x-4">
              <div className="w-20 h-20 bg-white bg-opacity-20 rounded-full flex items-center justify-center">
                <span className="text-2xl font-bold text-white">
                  {customer.name.split(' ').map(n => n[0]).join('').toUpperCase()}
                </span>
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white">{customer.name}</h2>
                <p className="text-blue-100">Customer ID: {customer._id.slice(-8)}</p>
                <div className="mt-2">
                  <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border ${tierInfo.color}`}>
                    {tierInfo.label} Member
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Customer Information */}
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {/* Personal Information */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <svg className="w-5 h-5 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                  Personal Information
                </h3>
                <div className="space-y-4">
                  <div className="flex justify-between items-center py-3 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-500">Full Name</span>
                    <span className="text-sm text-gray-900">{customer.name}</span>
                  </div>
                  <div className="flex justify-between items-center py-3 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-500">Date of Birth</span>
                    <span className="text-sm text-gray-900">{formatDate(customer.dateOfBirth)}</span>
                  </div>
                  <div className="flex justify-between items-center py-3 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-500">Age</span>
                    <span className="text-sm text-gray-900">{age} years old</span>
                  </div>
                </div>
              </div>

              {/* Membership Information */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <svg className="w-5 h-5 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                  </svg>
                  Membership Details
                </h3>
                <div className="space-y-4">
                  <div className="flex justify-between items-center py-3 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-500">Tier Level</span>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${tierInfo.color}`}>
                      {tierInfo.label} (Level {customer.memberNumber})
                    </span>
                  </div>
                  <div className="py-3 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-500 block mb-1">Benefits</span>
                    <span className="text-sm text-gray-900">{tierInfo.description}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Interests Section */}
            <div className="mt-8">
              <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                <svg className="w-5 h-5 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                </svg>
                Interests & Hobbies
              </h3>
              <div className="bg-gray-50 rounded-lg p-4">
                {customer.interests ? (
                  <p className="text-gray-700">{customer.interests}</p>
                ) : (
                  <p className="text-gray-500 italic">No interests specified</p>
                )}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="mt-8 flex justify-end space-x-4">
              <Link
                href="/fin-customer/customer"
                className="px-6 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Back to List
              </Link>
              <Link
                href={`/fin-customer/customer/edit/${customer._id}`}
                className="px-6 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors"
              >
                Edit Customer
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}