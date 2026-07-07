import 'package:flutter/material.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
      final dark = MHelperFunctions.isDarkMode(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: Sizes.getAppBarHeight(context),
            left: Sizes.defaultpadding,
            right: Sizes.defaultpadding,
            bottom: Sizes.defaultpadding,
          ),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
               
                children: [
                  Image(
                    image: AssetImage(dark ? 'assets/Logos/M_dark1152.png' : 'assets/Logos/M1152.png'),
                    height: 150,
                  ),
                  SizedBox(height: Sizes.screenHeight(context) * 0.02),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: Sizes.screenHeight(context) * 0.02),
                  Text(
                    'Please login to your account in accordance to your role',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              SizedBox(height: Sizes.screenHeight(context) * 0.02),

              Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: Sizes.screenHeight(context) * 0.02),
                  TextFormField(
                    obscureText: true,  
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    )
                  ),
      
                  Align(
                    alignment: Alignment.centerRight,
                  child: TextButton(onPressed: (){}, child: Text('Forgot Password?', style: TextStyle(color: MColors.primaryColor, ),textAlign: TextAlign.right,))),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side : BorderSide(
                          color: dark ? Colors.grey : Colors.black,
                        ),
                      ),
                      onPressed: () {
                        // Handle login logic here
                      },
                      child: Text('Login',style:TextStyle(color: dark ? Colors.white : Colors.black)),
                    ),
                  ),
                  /*SizedBox(width: double.infinity, child: 
                   OutlinedButton(onPressed: (){}, child: Text('Register', style: TextStyle(color: dark ? Colors.white : Colors.black)))
                  ),*/
                ]
              )
            ),
          
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              
              children: [
                SizedBox(height: Sizes.screenHeight(context) * 0.089),
                Flexible(child: Divider(color: dark ? Colors.white : Colors.grey, thickness: 0.5, indent: 60, endIndent: 5)),
                Text('Choose Your Role', style: Theme.of(context).textTheme.bodyMedium),
                Flexible(child: Divider(color: dark ? Colors.white : Colors.grey, thickness: 0.5, indent: 5, endIndent: 60))
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
      width: Sizes.screenWidth(context) * 0.37,
      height: Sizes.screenHeight(context) * 0.1,
      child: ElevatedButton(
        onPressed: () {
          // Handle Patient login logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: MColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        // Use a Column to position both the icon and text at the bottom
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Pushes everything to the bottom
            children: [
              const Icon(Icons.medical_services, color: Colors.white, size: 40), // Your Iconsax Icon
              const SizedBox(height: 10), // Space between icon and text
              Text(
                'Doctor',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    ),
                SizedBox(
      width: Sizes.screenWidth(context) * 0.37,
      height: Sizes.screenHeight(context) * 0.1,
      child: ElevatedButton(
        onPressed: () {
          // Handle Patient login logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: MColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        // Use a Column to position both the icon and text at the bottom
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Pushes everything to the bottom
            children: [
              const Icon(Iconsax.message_edit, color: Colors.white, size: 40), // Your Iconsax Icon
              const SizedBox(height: 10), // Space between icon and text
              Text(
                'Pharmacist',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    ),
                
            ],
          ),
          SizedBox(height: Sizes.screenHeight(context) * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                 SizedBox(
      width: Sizes.screenWidth(context) * 0.37,
      height: Sizes.screenHeight(context) * 0.1,
      child: ElevatedButton(
        onPressed: () {
          // Handle Patient login logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: MColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        // Use a Column to position both the icon and text at the bottom
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Pushes everything to the bottom
            children: [
              const Icon(Icons.science, color: Colors.white, size: 40), // Your Iconsax Icon
              const SizedBox(height: 10), // Space between icon and text
              Text(
                'Lab Specialist',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    ),
                SizedBox(
      width: Sizes.screenWidth(context) * 0.37,
      height: Sizes.screenHeight(context) * 0.1,
      child: ElevatedButton(
        onPressed: () {
          // Handle Patient login logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: MColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        // Use a Column to position both the icon and text at the bottom
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Pushes everything to the bottom
            children: [
              const Icon(Iconsax.user, color: Colors.white, size: 40), // Your Iconsax Icon
              const SizedBox(height: 10), // Space between icon and text
              Text(
                'Patient',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    ),
            ]
        ),
      ])
    )));
  }
}