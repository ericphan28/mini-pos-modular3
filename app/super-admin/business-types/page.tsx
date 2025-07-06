'use client';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { BusinessType, businessTypeService } from '@/lib/services/business-type.service';
import { useEffect, useState } from 'react';

// ✅ Tạo BusinessTypesTable component
interface BusinessTypesTableProps {
  types: BusinessType[];
  onUpdate: (value: string, updates: Partial<BusinessType>) => void;
  isLoading: boolean;
}

function BusinessTypesTable({ types, onUpdate, isLoading }: BusinessTypesTableProps) {
  if (isLoading) {
    return <div className="text-center py-8">Đang tải...</div>;
  }

  const toggleActive = (type: BusinessType) => {
    onUpdate(type.value, { active: !type.active });
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Danh sách loại hình kinh doanh ({types.length})</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {types.map((type) => (
            <div key={type.value} className="flex items-center justify-between p-4 border rounded-lg">
              <div className="flex items-center space-x-4">
                <span className="text-2xl">{type.icon}</span>
                <div>
                  <div className="font-medium">{type.label}</div>
                  <div className="text-sm text-gray-500">{type.description}</div>
                  <div className="text-xs text-gray-400">
                    Category: {type.category} | Sort: {type.sortOrder}
                  </div>
                </div>
              </div>
              <div className="flex items-center space-x-2">
                <Badge variant={type.active ? "default" : "secondary"}>
                  {type.active ? "Hoạt động" : "Tạm dừng"}
                </Badge>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => toggleActive(type)}
                >
                  {type.active ? "Tạm dừng" : "Kích hoạt"}
                </Button>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

// ✅ Tạo AddBusinessTypeForm component
interface AddBusinessTypeFormProps {
  onAdd: (typeData: BusinessType) => void;
}

function AddBusinessTypeForm({ onAdd }: AddBusinessTypeFormProps) {
  const [formData, setFormData] = useState({
    value: '',
    label: '',
    description: '',
    icon: '',
    category: 'other',
    sortOrder: 100
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.value || !formData.label) {
      alert('Vui lòng nhập đầy đủ thông tin bắt buộc');
      return;
    }

    onAdd({
      ...formData,
      active: true
    });

    // Reset form
    setFormData({
      value: '',
      label: '',
      description: '',
      icon: '',
      category: 'other',
      sortOrder: 100
    });
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Thêm loại hình kinh doanh mới</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="value">Mã loại hình *</Label>
              <Input
                id="value"
                value={formData.value}
                onChange={(e) => setFormData({...formData, value: e.target.value})}
                placeholder="vd: new_business_type"
                required
              />
            </div>
            <div>
              <Label htmlFor="label">Tên hiển thị *</Label>
              <Input
                id="label"
                value={formData.label}
                onChange={(e) => setFormData({...formData, label: e.target.value})}
                placeholder="vd: 🏪 Loại hình mới"
                required
              />
            </div>
          </div>
          
          <div>
            <Label htmlFor="description">Mô tả</Label>
            <Input
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              placeholder="Mô tả chi tiết về loại hình kinh doanh"
            />
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <Label htmlFor="icon">Icon</Label>
              <Input
                id="icon"
                value={formData.icon}
                onChange={(e) => setFormData({...formData, icon: e.target.value})}
                placeholder="🏪"
              />
            </div>
            <div>
              <Label htmlFor="category">Category</Label>
              <select
                id="category"
                className="w-full p-2 border rounded"
                value={formData.category}
                onChange={(e) => setFormData({...formData, category: e.target.value})}
              >
                <option value="retail">Retail</option>
                <option value="food">Food</option>
                <option value="beauty">Beauty</option>
                <option value="healthcare">Healthcare</option>
                <option value="professional">Professional</option>
                <option value="technical">Technical</option>
                <option value="entertainment">Entertainment</option>
                <option value="industrial">Industrial</option>
                <option value="service">Service</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div>
              <Label htmlFor="sortOrder">Thứ tự sắp xếp</Label>
              <Input
                id="sortOrder"
                type="number"
                value={formData.sortOrder}
                onChange={(e) => setFormData({...formData, sortOrder: parseInt(e.target.value)})}
              />
            </div>
          </div>

          <Button type="submit" className="w-full">
            Thêm loại hình kinh doanh
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

// ✅ Main page component
export default function BusinessTypesManagementPage() {
  const [businessTypes, setBusinessTypes] = useState<BusinessType[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Load business types from database
  const loadBusinessTypes = async () => {
    try {
      const types = await businessTypeService.getBusinessTypesFromDB();
      setBusinessTypes(types);
    } catch (error) {
      console.error('Error loading business types:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Load data on mount
  useEffect(() => {
    loadBusinessTypes();
  }, []);

  // Add new business type
  const handleAddType = async (typeData: BusinessType) => {
    const success = await businessTypeService.addBusinessType(typeData);
    if (success) {
      await loadBusinessTypes();
    }
  };

  // Update business type
  const handleUpdateType = async (value: string, updates: Partial<BusinessType>) => {
    const success = await businessTypeService.updateBusinessType(value, updates);
    if (success) {
      await loadBusinessTypes();
    }
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Quản lý loại hình kinh doanh</h1>
      
      {/* Business Types Table */}
      <BusinessTypesTable 
        types={businessTypes}
        onUpdate={handleUpdateType}
        isLoading={isLoading}
      />
      
      {/* Add New Type Form */}
      <AddBusinessTypeForm onAdd={handleAddType} />
    </div>
  );
}