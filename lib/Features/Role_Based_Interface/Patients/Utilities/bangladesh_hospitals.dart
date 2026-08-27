class HospitalContact {
  const HospitalContact({
    required this.name,
    required this.area,
    required this.phone,
  });

  final String name;
  final String area;
  final String phone;
}

// Demo directory — real, well-known Bangladesh hospitals so the list is
// useful in a pinch, but phone numbers are switchboard-style placeholders,
// not verified live numbers. Swap for a maintained/verified dataset (or a
// Firestore-backed one) before release.
const List<HospitalContact> kNearbyHospitals = [
  HospitalContact(
    name: 'Dhaka Medical College Hospital',
    area: 'Shahbagh, Dhaka',
    phone: '+880 2-55165088',
  ),
  HospitalContact(
    name: 'Bangabandhu Sheikh Mujib Medical University',
    area: 'Shahbagh, Dhaka',
    phone: '+880 2-9661051',
  ),
  HospitalContact(
    name: 'Square Hospital',
    area: 'Panthapath, Dhaka',
    phone: '+880 2-8144400',
  ),
  HospitalContact(
    name: 'United Hospital',
    area: 'Gulshan, Dhaka',
    phone: '+880 2-8836000',
  ),
  HospitalContact(
    name: 'Evercare Hospital',
    area: 'Bashundhara, Dhaka',
    phone: '+880 2-8431661',
  ),
  HospitalContact(
    name: 'Labaid Hospital',
    area: 'Dhanmondi, Dhaka',
    phone: '+880 2-9676356',
  ),
  HospitalContact(
    name: 'Ibn Sina Hospital',
    area: 'Dhanmondi, Dhaka',
    phone: '+880 2-9611720',
  ),
  HospitalContact(
    name: 'BIRDEM General Hospital',
    area: 'Shahbagh, Dhaka',
    phone: '+880 2-9661551',
  ),
  HospitalContact(
    name: 'Holy Family Red Crescent Hospital',
    area: 'Eskaton, Dhaka',
    phone: '+880 2-8315261',
  ),
  HospitalContact(
    name: 'Kurmitola General Hospital',
    area: 'Kurmitola, Dhaka',
    phone: '+880 2-8901351',
  ),
  HospitalContact(
    name: 'Combined Military Hospital (CMH)',
    area: 'Dhaka Cantonment, Dhaka',
    phone: '+880 2-8750041',
  ),
  HospitalContact(
    name: 'National Institute of Cardiovascular Diseases',
    area: 'Sher-e-Bangla Nagar, Dhaka',
    phone: '+880 2-9122560',
  ),
  HospitalContact(
    name: 'National Institute of Neurosciences',
    area: 'Sher-e-Bangla Nagar, Dhaka',
    phone: '+880 2-9124215',
  ),
  HospitalContact(
    name: 'Dhaka Shishu Hospital',
    area: 'Sher-e-Bangla Nagar, Dhaka',
    phone: '+880 2-9130476',
  ),
  HospitalContact(
    name: 'Sir Salimullah Medical College Hospital',
    area: 'Mitford, Dhaka',
    phone: '+880 2-57391101',
  ),
  HospitalContact(
    name: 'Green Life Medical College Hospital',
    area: 'Dhanmondi, Dhaka',
    phone: '+880 2-9611350',
  ),
  HospitalContact(
    name: 'Anwer Khan Modern Hospital',
    area: 'Dhanmondi, Dhaka',
    phone: '+880 2-58611350',
  ),
  HospitalContact(
    name: 'Popular Medical College Hospital',
    area: 'Dhanmondi, Dhaka',
    phone: '+880 2-9661412',
  ),
  HospitalContact(
    name: 'Central Hospital',
    area: 'Dhanmondi, Dhaka',
    phone: '+880 2-8610793',
  ),
  HospitalContact(
    name: 'Apollo Hospitals Dhaka',
    area: 'Bashundhara, Dhaka',
    phone: '+880 2-8401661',
  ),
  HospitalContact(
    name: 'Chittagong Medical College Hospital',
    area: 'Panchlaish, Chattogram',
    phone: '+880 31-619400',
  ),
  HospitalContact(
    name: 'Chattogram General Hospital',
    area: 'Chattogram',
    phone: '+880 31-619467',
  ),
  HospitalContact(
    name: 'Evercare Hospital Chattogram',
    area: 'Chattogram',
    phone: '+880 31-2550362',
  ),
  HospitalContact(
    name: 'Sylhet MAG Osmani Medical College Hospital',
    area: 'Sylhet',
    phone: '+880 821-713336',
  ),
  HospitalContact(
    name: 'Sylhet Women\'s Medical College Hospital',
    area: 'Sylhet',
    phone: '+880 821-725881',
  ),
  HospitalContact(
    name: 'Khulna Medical College Hospital',
    area: 'Khulna',
    phone: '+880 41-760325',
  ),
  HospitalContact(
    name: 'Khulna City Medical College Hospital',
    area: 'Khulna',
    phone: '+880 41-731590',
  ),
  HospitalContact(
    name: 'Rajshahi Medical College Hospital',
    area: 'Rajshahi',
    phone: '+880 721-772020',
  ),
  HospitalContact(
    name: 'Rangpur Medical College Hospital',
    area: 'Rangpur',
    phone: '+880 521-62550',
  ),
  HospitalContact(
    name: 'Sher-e-Bangla Medical College Hospital',
    area: 'Barishal',
    phone: '+880 431-2172441',
  ),
  HospitalContact(
    name: 'Mymensingh Medical College Hospital',
    area: 'Mymensingh',
    phone: '+880 91-66351',
  ),
  HospitalContact(
    name: 'Cumilla Medical College Hospital',
    area: 'Cumilla',
    phone: '+880 81-76350',
  ),
  HospitalContact(
    name: 'Faridpur Medical College Hospital',
    area: 'Faridpur',
    phone: '+880 631-63307',
  ),
  HospitalContact(
    name: 'Bogura Shaheed Ziaur Rahman Medical College Hospital',
    area: 'Bogura',
    phone: '+880 51-66591',
  ),
  HospitalContact(
    name: 'Dinajpur M. Abdur Rahim Medical College Hospital',
    area: 'Dinajpur',
    phone: '+880 531-64386',
  ),
  HospitalContact(
    name: 'Jashore General Hospital',
    area: 'Jashore',
    phone: '+880 421-68766',
  ),
  HospitalContact(
    name: 'Cox\'s Bazar Sadar Hospital',
    area: "Cox's Bazar",
    phone: '+880 341-51041',
  ),
];
