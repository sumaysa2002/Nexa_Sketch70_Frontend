import 'package:flutter/material.dart';

final List<String> stickerPaths = [
  'assets/images/building.png',
  'assets/images/buddha.png',
  'assets/images/gas-station.png',
  'assets/images/tree-silhouette.png',
  'assets/images/flagpole.png',
  'assets/images/school.png',
  'assets/images/football-field.png',
  'assets/images/water-tower.png',
  'assets/images/electric-tower.png',
  'assets/images/triangle.png',
  'assets/images/Rf.png',
  'assets/images/bridge.png',
  'assets/images/home_small.png',
  'assets/images/home_medium.png',
  'assets/images/home_leang.png',
  'assets/images/rice2.png',
  'assets/images/grass.png',
  'assets/images/circular sign02.png',
  'assets/images/square.png',
  'assets/images/parking.png'
];

final List<String> drawIconPaths = [
  'assets/images/draw_icon/1_RF1.PNG',
  'assets/images/draw_icon/2_RF2.PNG',
  'assets/images/draw_icon/3_Mark.png',
  'assets/images/draw_icon/4_Flag.png',
  'assets/images/draw_icon/5_School.png',
  'assets/images/draw_icon/6_Temple.png',
  'assets/images/draw_icon/7_Airport.png',
  'assets/images/draw_icon/8_Gas_station.png',
  'assets/images/draw_icon/9_Bathroom.png',
  'assets/images/draw_icon/10_Milestone.png',
  'assets/images/draw_icon/11_High_voltage_power_poles.png',
  'assets/images/draw_icon/12_Water_tank.png',
  'assets/images/draw_icon/13_Motorcycle.png',
  'assets/images/draw_icon/14_Car.png',
  'assets/images/draw_icon/15_Car.png',
  'assets/images/draw_icon/16_Car_group.png',
  'assets/images/draw_icon/17_Tree.png',
  'assets/images/draw_icon/18_Tree_group.png',
  'assets/images/draw_icon/19_Grass.png',
  'assets/images/draw_icon/20_Grass_group.png',
  'assets/images/draw_icon/21_Rice.png',
  'assets/images/draw_icon/22_Rice_group.png',
  'assets/images/draw_icon/23_Circular_traffic_sign.png',
  'assets/images/draw_icon/24_Triangular_traffic_sign.png',
  'assets/images/draw_icon/25_Rectangular_traffic_sign.png',
  'assets/images/draw_icon/26_Rectangular_traffic_sign.png',
  'assets/images/draw_icon/27_Octagonal_traffic_sign.png',
];

final List<Widget> dummyWidgets = stickerPaths.map((path) {
  return SizedBox(
    width: 150,
    height: 150,
    child: Image.asset(
      path,
      fit: BoxFit.cover,
    ),
  );
}).toList();