import '../../core/enums/user_role.dart';
import '../dummy/dummy_users.dart';
import '../models/user_model.dart';

class UserRepository {
  const UserRepository();

  List<UserModel> getEmployees({bool? isActive}) {
    return dummyUsers.where((user) {
      final isEmployee = user.role == UserRole.employee;
      final matchesStatus = isActive == null || user.isActive == isActive;
      return isEmployee && matchesStatus;
    }).toList();
  }

  UserModel? getEmployeeById(String userId) {
    for (final user in dummyUsers) {
      if (user.id == userId && user.role == UserRole.employee) {
        return user;
      }
    }

    return null;
  }

  List<UserModel> getAttendanceUsers({bool? isActive}) {
    return dummyUsers.where((user) {
      final matchesStatus = isActive == null || user.isActive == isActive;
      return matchesStatus;
    }).toList();
  }

  UserModel? getAttendanceUserById(String userId) {
    for (final user in dummyUsers) {
      if (user.id == userId) {
        return user;
      }
    }

    return null;
  }
}
