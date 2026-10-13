import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/session_helpers.dart';
import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../services/location_service.dart';
import '../../../widgets/widgets.dart';
import '../bloc/site_form_bloc.dart';

class AddSiteScreen extends StatefulWidget {
  final SiteLocal? site;
  final CustomerLocal? customer;
  const AddSiteScreen({super.key, this.site, this.customer});

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.site?.siteName);
  late final _address = TextEditingController(text: widget.site?.address);
  late String? _customerId = widget.site?.customerId ?? widget.customer?.id;
  late double? _lat = widget.site?.latitude;
  late double? _lng = widget.site?.longitude;
  List<CustomerView> _customers = const [];
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final list = await context.read<CustomerRepository>().list(currentUserId(context));
    if (mounted) setState(() => _customers = list);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    setState(() => _locating = true);
    final point = await context.read<LocationService>().getCurrent(context);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (point != null) {
        _lat = point.latitude;
        _lng = point.longitude;
      }
    });
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<SiteFormBloc>().add(SiteSubmitted(SiteDraft(
          customerId: _customerId!,
          name: _name.text,
          address: _address.text,
          latitude: _lat,
          longitude: _lng,
        )));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.site != null;
    final hasLocation = _lat != null && _lng != null;

    return BlocConsumer<SiteFormBloc, SubmitState>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          final m = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          m.showSnackBar(SnackBar(
            content: Text(editing ? 'Site updated' : 'Site added'),
            behavior: SnackBarBehavior.floating,
          ));
        } else if (state.status == SubmitStatus.failure) {
          snack(context, state.error ?? 'Could not save the site.');
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(editing ? 'Edit Site' : 'Add Site')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            AnimatedEntrance(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const FormSectionTitle(Icons.location_city, 'Site Information'),
                  AppField(label: 'Site Name', hint: 'Enter site name', controller: _name, isRequired: true),
                  AppDropdown<String>(
                    label: 'Customer',
                    hint: 'Select customer',
                    isRequired: true,
                    value: _customers.any((c) => c.customer.id == _customerId) ? _customerId : null,
                    items: _customers
                        .map((c) => DropdownMenuItem(value: c.customer.id, child: Text(c.customer.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _customerId = v),
                  ),
                  AppField(label: 'Address', hint: 'Enter site address', controller: _address, maxLines: 2),
                  const FieldLabel('Location (Optional)'),
                  const MapPlaceholder(),
                  const SizedBox(height: 8),
                  if (hasLocation)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.red),
                        const SizedBox(width: 4),
                        Text('${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ]),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    onPressed: _locating ? null : _pickLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(hasLocation ? 'Update Location' : 'Pick Location'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AppButton('Cancel', outlined: true, onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(child: AppButton('Save', isLoading: state.isSaving, onPressed: _save)),
            ]),
          ]),
        ),
      ),
    );
  }
}
