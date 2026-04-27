import 'package:equatable/equatable.dart';

class HolidayModel extends Equatable {
  const HolidayModel({
    required this.id,
    required this.date,
    required this.name,
  });

  final String id;
  final DateTime date;
  final String name;

  @override
  List<Object?> get props => [id, date, name];
}
