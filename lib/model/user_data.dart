class UserData {
  String name;
  int phone;
  String email;
  String address;
  static String image = "";

  UserData(this.name,this.phone,this.email,this.address);

  setImage (String _image) {image = _image;}
}