import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../widgets/widgets.dart';
import '../bloc/customer_form_bloc.dart';

class AddCustomerScreen extends StatefulWidget {
  final CustomerLocal? customer;
  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _contact = TextEditingController(text: widget.customer?.contactPerson);
  late final _email = TextEditingController(text: widget.customer?.email);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _address = TextEditingController(text: widget.customer?.address);

  @override
  void dispose() {
    for (final c in [_name, _contact, _email, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<CustomerFormBloc>().add(CustomerSubmitted(CustomerDraft(
          name: _name.text,
          contactPerson: _contact.text,
          email: _email.text,
          phone: _phone.text,
          address: _address.text,
        )));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.customer != null;

    return BlocConsumer<CustomerFormBloc, SubmitState>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          final m = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          m.showSnackBar(SnackBar(
            content: Text(editing ? 'Customer updated' : 'Customer added'),
            behavior: SnackBarBehavior.floating,
          ));
        } else if (state.status == SubmitStatus.failure) {
          snack(context, state.error ?? 'Could not save the customer.');
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(editing ? 'Edit Customer' : 'Add Customer')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            AnimatedEntrance(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const FormSectionTitle(Icons.person_outline, 'Customer Information'),
                  AppField(label: 'Name', hint: 'Enter customer name', controller: _name, isRequired: true),
                  AppField(label: 'Contact Person', hint: 'Enter contact person', controller: _contact),
                  AppField(
                      label: 'Email',
                      hint: 'Enter email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress),
                  AppField(
                      label: 'Phone',
                      hint: 'Enter phone number',
                      controller: _phone,
                      keyboardType: TextInputType.phone),
                  AppField(label: 'Address', hint: 'Enter address', controller: _address, maxLines: 2),
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
