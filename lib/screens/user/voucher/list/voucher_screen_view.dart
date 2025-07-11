import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_state.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_view.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';

import '../../../../enums/processing/process_state_enum.dart';
import '../../../../objects/voucher_related/voucher.dart';
import '../../../../widgets/dialog/information_dialog.dart';
import '../../../../widgets/general/app_text_style.dart';
import '../../../../widgets/voucher/voucher_widget.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => VoucherScreenCubit(),
        child: const VoucherScreen(),
      );

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen>
    with SingleTickerProviderStateMixin {
  VoucherScreenCubit get cubit => context.read<VoucherScreenCubit>();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    cubit.toLoading();
    Future.microtask(() async {
      await cubit.initialize();
    });
    tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: GradientText(text: S.of(context).voucher),
          bottom: TabBar(
            controller: tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabAlignment: TabAlignment.fill,
            indicator: const BoxDecoration(),
            tabs: [
              Tab(text: S.of(context).ongoing),
              Tab(text: S.of(context).upcoming),
            ],
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<VoucherScreenCubit, VoucherScreenState>(
            listener: (context, state) {
              if (state.processState == ProcessState.success) {
                // Only show dialog if there's a dialog message and name
                if (state.dialogMessage.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => InformationDialog(
                      title: state.dialogName.description,
                      content: state.dialogMessage,
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    VoucherScreen.newInstance()));
                      },
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              // Show loading indicator while data is being fetched
              if (state.processState == ProcessState.loading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Show error message if the initialization failed
              if (state.processState == ProcessState.failure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.of(context).error,
                        style: AppTextStyle.regularText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.dialogMessage,
                        style: AppTextStyle.regularText,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          cubit.toLoading();
                          Future.microtask(() async {
                            await cubit.initialize();
                          });
                        },
                        child: Text(S.of(context).retry),
                      ),
                    ],
                  ),
                );
              }

              // Show the content when data is loaded
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Tab 1: Ongoing voucher list
                    state.ongoingList.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noVouchersAvailable,
                              style: AppTextStyle.regularText,
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.ongoingList.length,
                            itemBuilder: (context, index) {
                              final voucher = state.ongoingList[index];
                              return VoucherWidget(
                                voucher: voucher,
                                onPressed: () =>
                                    _onVoucherTap(context, voucher),
                              );
                            },
                          ),

                    // Tab 2: Upcoming voucher list
                    state.upcomingList.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noVouchersAvailable,
                              style: AppTextStyle.regularText,
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.upcomingList.length,
                            itemBuilder: (context, index) {
                              final voucher = state.upcomingList[index];
                              return VoucherWidget(
                                voucher: voucher,
                                onPressed: () =>
                                    _onVoucherTap(context, voucher),
                              );
                            },
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onVoucherTap(BuildContext context, Voucher voucher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoucherDetailScreen.newInstance(voucher),
      ),
    );
  }
}
