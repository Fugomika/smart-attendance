import '../../core/enums/user_role.dart';
import '../models/user_model.dart';

const dummyUsers = [
  UserModel(
    id: 'admin-1',
    name: 'Admin',
    email: 'admin@gmail.com',
    role: UserRole.admin,
    isActive: true,
  ),
  UserModel(
    id: 'user-1',
    name: 'User',
    email: 'user@gmail.com',
    role: UserRole.employee,
    isActive: true,
  ),
  UserModel(
    id: 'employee-1',
    name: 'Egi Meisandi',
    email: 'egi@gmail.com',
    role: UserRole.employee,
    isActive: true,
  ),
  UserModel(
    id: 'employee-2',
    name: 'Qonita',
    email: 'qonita@gmail.com',
    role: UserRole.employee,
    isActive: true,
  ),
  UserModel(
    id: 'employee-4',
    name: 'Ella Aurelia',
    email: 'ella@gmail.com',
    role: UserRole.employee,
    isActive: true,
  ),
  UserModel(
    id: 'employee-3',
    name: 'Abdurrahman Farras',
    email: 'farras@gmail.com',
    role: UserRole.employee,
    isActive: false,
  ),
];
