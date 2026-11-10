export 'dart:io';
export 'dart:async';
export 'dart:typed_data';
export 'package:path_provider/path_provider.dart';
export 'package:flutter/widgets.dart'; // สำหรับ FileImage/evict
export 'package:flutter/material.dart';
export 'package:flutter_bloc/flutter_bloc.dart';
export 'package:hive_flutter/hive_flutter.dart';
export 'package:flutter/services.dart';
export 'package:iconly/iconly.dart';
export 'dart:convert';
export 'package:connectivity_plus/connectivity_plus.dart';
export 'package:http_parser/http_parser.dart';
export 'package:path/path.dart' hide Context, context;
export 'package:sqflite/sqflite.dart';
export 'package:flutter_secure_storage/flutter_secure_storage.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:flutter/foundation.dart';
export 'package:image_picker/image_picker.dart';
export 'package:image_cropper/image_cropper.dart';
export 'package:flutter_image_compress/flutter_image_compress.dart';
export 'package:pinput/pinput.dart';
export 'package:date_format/date_format.dart';
export 'package:pdf/pdf.dart';
export 'package:printing/printing.dart';
export 'package:flutter_colorpicker/flutter_colorpicker.dart';
export 'package:table_calendar/table_calendar.dart';



export 'package:nexa_sketch/main.dart';

// core--------------------
export 'package:nexa_sketch/core/constants/constants.dart';
export 'package:nexa_sketch/core/services/app_exception.dart';
export 'package:nexa_sketch/core/services/pending_point_image_service.dart';
export 'package:nexa_sketch/core/services/secure_image.dart';
export 'package:nexa_sketch/core/services/sp_service.dart';
export 'package:nexa_sketch/core/services/sync_service.dart';
export 'package:nexa_sketch/core/services/thai_address_service.dart';

// features--------------------
export 'package:nexa_sketch/features/auth/bloc/bottom_nav_cubit.dart';
export 'package:nexa_sketch/features/auth/cubit/auth_cubit.dart';
//export 'package:nexa_sketch/features/auth/cubit/auth_state.dart';
export 'package:nexa_sketch/features/auth/cubit/point_task_cubit.dart';
//export 'package:nexa_sketch/features/auth/cubit/point_task_state.dart';
export 'package:nexa_sketch/features/auth/cubit/task_cubit.dart';
//export 'package:nexa_sketch/features/auth/cubit/task_state.dart';

// authentication --------------------
export 'package:nexa_sketch/features/auth/pages/authentication/login/login_page.dart';
export 'package:nexa_sketch/features/auth/pages/authentication/login/otp_login_page.dart';
export 'package:nexa_sketch/features/auth/pages/authentication/reset_password/otp_reset_password_page.dart';
export 'package:nexa_sketch/features/auth/pages/authentication/signup/otp_signup_page.dart';
export 'package:nexa_sketch/features/auth/pages/authentication/signup/signup_page.dart';
export 'package:nexa_sketch/features/auth/pages/authentication/reset_password/reset_password_page.dart';
export 'package:nexa_sketch/features/auth/pages/authentication/splash_page.dart';

export 'package:nexa_sketch/features/auth/pages/about_us/about_us_page.dart';

export 'package:nexa_sketch/features/auth/pages/home/admin_home_page.dart';
export 'package:nexa_sketch/features/auth/pages/home/nulluser_home_page.dart';
export 'package:nexa_sketch/features/auth/pages/home/user_home_page.dart';

export 'package:nexa_sketch/features/auth/pages/point/create_point/create_new_point_page.dart';
export 'package:nexa_sketch/features/auth/pages/point/create_point/draw_create_new_point.dart';
export 'package:nexa_sketch/features/auth/pages/point/point_detail_editor_page.dart';
export 'package:nexa_sketch/features/auth/pages/point/point_detail_viewer_page.dart' hide icon_Item;

//export 'package:nexa_sketch/features/auth/pages/point/editor/note_create_new_point.dart';
//export 'package:nexa_sketch/features/auth/pages/point/editor/admin_project_detail_editor_page.dart';
//export 'package:nexa_sketch/features/auth/pages/point/editor/user_project_detail_editor_page.dart';
//export 'package:nexa_sketch/features/auth/pages/point/viewer/user_project_detail_viewer_page.dart';

export 'package:nexa_sketch/features/auth/pages/profile/profile_edit_page.dart';
export 'package:nexa_sketch/features/auth/pages/profile/profile_page.dart';
export 'features/auth/pages/profile/profile_reset_password_page.dart';
export 'package:nexa_sketch/features/auth/pages/profile/signature_page.dart';

export 'package:nexa_sketch/features/auth/pages/project/create_new_project_page.dart';
export 'package:nexa_sketch/features/auth/pages/project/edit_project_page.dart';
export 'package:nexa_sketch/features/auth/pages/project/export_project.dart';
export 'package:nexa_sketch/features/auth/pages/project/editor/admin_project_detail_editor_page.dart';
export 'package:nexa_sketch/features/auth/pages/project/editor/user_project_detail_editor_page.dart';
export 'package:nexa_sketch/features/auth/pages/project/viewer/user_project_detail_viewer_page.dart';


export 'package:nexa_sketch/features/auth/pages/approved_users/admin_approved_users_page.dart';
export 'package:nexa_sketch/features/auth/pages/approved_users/nulluser_approved_users_page.dart';
export 'package:nexa_sketch/features/auth/pages/approved_users/user_approved_users_page.dart';

export 'package:nexa_sketch/features/auth/repository/auth_local_repository.dart';
export 'package:nexa_sketch/features/auth/repository/auth_remote_repository.dart';
export 'package:nexa_sketch/features/auth/repository/point_task_local_repository.dart';
export 'package:nexa_sketch/features/auth/repository/point_task_remote_repository.dart';
export 'package:nexa_sketch/features/auth/repository/task_local_repository.dart';
export 'package:nexa_sketch/features/auth/repository/task_remote_repository.dart';

export 'package:nexa_sketch/features/widgets/phone_format.dart';
export 'package:nexa_sketch/features/widgets/point_image_widget.dart';
export 'package:nexa_sketch/features/widgets/snackbar.dart';
export 'package:nexa_sketch/features/widgets/calender/calendar.dart';

export "package:nexa_sketch/features/widgets/alert/alert_image_one_button.dart";
export "package:nexa_sketch/features/widgets/alert/alert_image_two_button.dart";

export 'package:nexa_sketch/features/widgets/button/button_icon.dart';
export 'package:nexa_sketch/features/widgets/button/circle_icon_button.dart';
export 'package:nexa_sketch/features/widgets/button/draw_tool_button.dart';

export 'package:nexa_sketch/features/widgets/card/list_project_card.dart';
export 'package:nexa_sketch/features/widgets/card/list_point_card.dart';
export 'package:nexa_sketch/features/widgets/card/revoked_member_badge.dart';

export 'package:nexa_sketch/features/widgets/draw/drawing_area.dart';
export 'package:nexa_sketch/features/widgets/draw/mycustompainter.dart';
export 'package:nexa_sketch/features/widgets/draw/saved_drawing.dart';
//export 'package:nexa_sketch/features/widgets/draw/saved_drawing.g.dart';
export 'package:nexa_sketch/features/widgets/draw/shape_curve.dart';
export 'package:nexa_sketch/features/widgets/draw/shape_object.dart';
export 'package:nexa_sketch/features/widgets/draw/shape_circle.dart';
export 'package:nexa_sketch/features/widgets/draw/shape_painter.dart';
export 'package:nexa_sketch/features/widgets/draw/stroke_model.dart';
export 'package:nexa_sketch/features/widgets/draw/arrowpainter.dart';
export 'package:nexa_sketch/features/widgets/draw/draggable_curve.dart';
export 'package:nexa_sketch/features/widgets/draw/draggable_icon.dart';
export 'package:nexa_sketch/features/widgets/draw/draggable_shape.dart';
export 'package:nexa_sketch/features/widgets/draw/draggable_text.dart';
export 'package:nexa_sketch/features/widgets/draw/wexport.dart';
export 'package:nexa_sketch/features/widgets/draw/icon_list.dart';
export 'package:nexa_sketch/features/widgets/draw/linestyle.dart';
export 'package:nexa_sketch/features/widgets/draw/linestyle_popup.dart';
export 'package:nexa_sketch/features/widgets/draw/overlayed_widget.dart';
export 'package:nexa_sketch/features/widgets/draw/icon_popup.dart';
export 'package:nexa_sketch/features/widgets/draw/shape_triangle_square.dart';
export 'package:nexa_sketch/features/widgets/draw/transformlayer.dart';

export 'package:nexa_sketch/features/widgets/otp/otp_status_panel.dart';
//export 'package:nexa_sketch/features/widgets/otp/app_exception.dart';

export 'package:nexa_sketch/features/widgets/dropdown/dropdown_field_c5.dart';
export 'package:nexa_sketch/features/widgets/dropdown/point_dropdown_field_column_c30.dart';
export 'package:nexa_sketch/features/widgets/dropdown/point_dropdown_field_row_c30.dart';
export 'package:nexa_sketch/features/widgets/field/text_field_column_c5.dart';
export 'package:nexa_sketch/features/widgets/field/point_text_field_column_c30.dart';
export 'package:nexa_sketch/features/widgets/field/point_text_field_row_c30.dart';
export 'package:nexa_sketch/features/widgets/field/text_field_column_c5.dart';
export 'package:nexa_sketch/features/widgets/field/text_field_login.dart';
export 'package:nexa_sketch/features/widgets/navigation_bar/admin_main_wrapper.dart';
export 'package:nexa_sketch/features/widgets/navigation_bar/nulluser_main_wrapper.dart';
export 'package:nexa_sketch/features/widgets/navigation_bar/user_main_wrapper.dart';
export 'package:nexa_sketch/features/widgets/text/point_title.dart';
export 'package:nexa_sketch/features/widgets/text/w_text_big.dart';
export 'package:nexa_sketch/features/widgets/text/w_text_thai.dart';
export 'package:nexa_sketch/features/widgets/text/w_text_thai_notosansthai.dart';

// models--------------------
export 'package:nexa_sketch/models/point_model.dart';
export 'package:nexa_sketch/models/project_model.dart';
export 'package:nexa_sketch/models/signup_payload.dart';
export 'package:nexa_sketch/models/user_model.dart';



