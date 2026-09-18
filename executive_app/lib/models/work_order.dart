class WorkOrder {
  final String id;
  final String displayId;
  final String customerName;
  final String customerPhone;
  final String address;
  final String? customerCoordinates;
  final String description;
  final String status; // ASSIGNED, ACCEPTED, IN_PROGRESS, PENDING, COMPLETED, CANCELLED
  final String complaintType;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? pendingAt;
  final DateTime? completedAt;

  WorkOrder({
    required this.id,
    required this.displayId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    this.customerCoordinates,
    required this.description,
    required this.status,
    required this.complaintType,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.pendingAt,
    this.completedAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'] ?? '',
      displayId: json['displayId'] ?? json['workOrderId'] ?? '',
      customerName: json['customerName'] ?? 'Unknown Customer',
      customerPhone: json['customerPhone'] ?? json['customerMobile'] ?? '',
      address: json['address'] ?? json['customerAddress'] ?? 'No address provided',
      customerCoordinates: json['customerCoordinates'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      complaintType: json['complaintType'] ?? 'General',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      pendingAt: json['pendingAt'] != null ? DateTime.parse(json['pendingAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}
