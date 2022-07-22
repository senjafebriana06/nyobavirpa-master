import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nyobavirpa/headSizeForm.dart';
import 'package:nyobavirpa/models/profile_model.dart';
import 'package:nyobavirpa/profileForm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  SharedPreferences? prefs;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ProfileModel>(
          future: _getProfile(),
          builder: (context, profileSnap) {
            if (profileSnap.data?.nama == null ||
                profileSnap.data?.jenisKelamin == null ||
                profileSnap.data?.umur == null) {
              return Container(
                child: Center(child: Text("Loading")),
              );
            }
            if (profileSnap.data?.nama == "" ||
                profileSnap.data?.jenisKelamin == "" ||
                profileSnap.data?.umur == 0) {
              print(profileSnap.data?.jenisKelamin);
              return Container(
                padding: const EdgeInsets.all(18.0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Profil Belum Diisi"),
                    const SizedBox(
                      height: 18.0,
                    ),
                    InkWell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        width: 100.0,
                        color: Colors.orange,
                        child: Center(child: Text("Isi profile")),
                      ),
                      onTap: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ProfileForm()))
                            .then;
                        ;
                      },
                    )
                  ],
                ),
              );
            }
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (profileSnap.data?.nama)!,
                    style: TextStyle(fontSize: 28.0),
                  ),
                  Text((profileSnap.data?.jenisKelamin)! == "L"
                      ? "Laki-laki"
                      : "Perempuan"),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Tanggal Lahir : "),
                      Text((profileSnap.data?.tanggalLahir)!),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Umur : "),
                      Text((profileSnap.data?.umur)!.toString()),
                      Text(" bulan"),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  if ((profileSnap.data?.lingkarKepala) != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Lingkar Kepala : "),
                        Text((profileSnap.data?.lingkarKepala).toString()),
                        Text(" cm"),
                      ],
                    ),
                  SizedBox(
                    height: 8,
                  ),
                  if ((profileSnap.data?.statusLingkarKepala) != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Status Lingkar Kepala : "),
                        Text((profileSnap.data?.statusLingkarKepala)!),
                      ],
                    ),
                  SizedBox(
                    height: 18,
                  ),
                  InkWell(
                    child: Container(
                      child: Center(
                          child: Text(
                        "Ubah Profile",
                        style: TextStyle(color: Colors.white),
                      )),
                      color: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      width: 175.0,
                    ),
                    onTap: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileForm()));
                    },
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  InkWell(
                    child: Container(
                      child: Center(
                          child: Text(
                        "Ubah Lingkar Kepala",
                        style: TextStyle(color: Colors.white),
                      )),
                      color: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      width: 175.0,
                    ),
                    onTap: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HeadSizeForm()));
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<ProfileModel> _getProfile() async {
    prefs = await SharedPreferences.getInstance();
    String? id = prefs?.getString("id");
    ProfileModel profileModel = ProfileModel(
        jenisKelamin: "",
        nama: "",
        umur: 0,
        tanggalLahir: DateTime.now().toString(),
        lingkarKepala: 0.0,
        statusLingkarKepala: '');

    await firestore.collection("users").doc(id).get().then((result) {
      if (result.data()!['name'] != null &&
          result.data()!['gender'] != null &&
          result.data()!['age'] != null) {
        profileModel = ProfileModel(
            nama: result.data()!['name'],
            umur: result.data()!['age'],
            jenisKelamin: result.data()!['gender'],
            lingkarKepala: result.data()!['headSize'],
            tanggalLahir: result.data()!['dateOfBirth'],
            statusLingkarKepala: result.data()!['headSizeStatus']);
      }
    });
    return profileModel;
  }
}
