import 'package:cloud_firestore/cloud_firestore.dart';

class DirectoryPerson {
  final String id;
  final String name;
  final String role;
  final String department;
  final String phone;
  final String email;

  const DirectoryPerson({
    this.id = '',
    required this.name,
    required this.role,
    required this.department,
    required this.phone,
    required this.email,
  });

  factory DirectoryPerson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DirectoryPerson(
      id: doc.id,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      department: data['department'] as String? ?? '',
      phone: data['phone'] as String? ?? 'N/A',
      email: data['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'department': department,
      'phone': phone,
      'email': email,
    };
  }
}

bool isFaculty(DirectoryPerson p) {
  return p.name.startsWith('Dr.') || p.name.startsWith('Prof. ');
}

// Fallback data used only if Firestore fetch fails or returns empty
const List<DirectoryPerson> kAllDirectoryPeople = [
  DirectoryPerson(
    name: 'Dr. Patrick Awuah',
    role: 'President & Founder',
    department: 'Administration',
    phone: 'N/A',
    email: 'pawuah@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Dr. Ayorkor Korsah',
    role: 'Senior Lecturer and Head of Department',
    department: 'CS/IS',
    phone: '+233 30 2610 330',
    email: 'akorsah@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Prof. Angela Owusu-Ansah',
    role: 'Provost',
    department: "Provost's Office",
    phone: 'N/A',
    email: 'aowusu@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Nana-Afua Anoff',
    role: 'Senior Career Development Officer',
    department: 'Career Services',
    phone: 'N/A',
    email: 'nana-afua.anoff@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Elena Rosca',
    role: 'Senior Lecturer and Head of Department',
    department: 'Engineering',
    phone: 'N/A',
    email: 'erosca@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Ashesi Student Council',
    role: 'Student Government',
    department: 'Student Affairs',
    phone: 'N/A',
    email: 'studentcouncil@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'David Amatey Sampah',
    role: 'Lecturer',
    department: 'CS/IS',
    phone: '233 302 610 330',
    email: 'dsampah@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Student Life and Engagement',
    role: 'Student Affairs',
    department: 'Student Affairs',
    phone: 'N/A',
    email: 'sle@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Emmanuel Obeng Ntow',
    role: 'Senior Academic Advisor',
    department: 'Counselling and Coaching',
    phone: '+233 50 155 7079',
    email: 'emmanuel.ntow@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Gideon Ofori Osabutey',
    role: 'Lecturer',
    department: 'Climate Change & Global Innovation',
    phone: '+233 302 610 330',
    email: 'gosabutey@ashei.edu.gh',
  ),
  DirectoryPerson(
    name: 'David Ebo Adjepon-Yamoah',
    role: 'Lecturer',
    department: 'CS/IS',
    phone: 'N/A',
    email: 'dajepong@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Joseph Oduro-Frimpong',
    role: 'Senior Lecturer',
    department: 'Humanities and Social Sciences',
    phone: 'N/A',
    email: 'joduro-frimpong@ashesi.edu.gh',
  ),
  DirectoryPerson(
    name: 'Bridgette Addo Asiedu',
    role: 'Director',
    department: 'Health Center',
    phone: 'N/A',
    email: 'babakah@ashesi.edu.gh',
  ),
];
