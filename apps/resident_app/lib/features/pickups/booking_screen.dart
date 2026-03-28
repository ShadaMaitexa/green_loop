import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import 'package:geo/geo.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 1;
  
  // Selection state
  WasteType? _selectedWasteType;
  DateTime? _selectedDate;
  String? _selectedSlot;
  
  // Location state
  final _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  
  // Result state
  PickupResponse? _result;
  bool _isBooking = false;

  // Cache
  List<PickupSlot> _slots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    // In a full implementation we'd fetch the ResidentProfile here.
    // For now, if we don't have it, we'll let the user detect GPS.
  }

  void _nextStep() => setState(() => _currentStep++);
  void _prevStep() => setState(() => _currentStep--);

  Future<void> _loadSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final repo = Provider.of<PickupRepository>(context, listen: false);
      // Using wardId from a profile (assuming hardcoded 1 for demo if no profile fetched)
      final slots = await repo.getAvailability(1);
      setState(() {
        _slots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load slots: $e')),
        );
      }
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _handleLocationDetection() async {
    final locationService = LocationService();
    try {
      final position = await locationService.getCurrentPosition();
      final address = await locationService.getAddressFromLatLng(position.latitude, position.longitude);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (address != null) _addressController.text = address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedWasteType == null || _selectedDate == null || _selectedSlot == null) return;
    
    setState(() => _isBooking = true);
    try {
      final repo = Provider.of<PickupRepository>(context, listen: false);
      final request = PickupRequest(
        wasteType: _selectedWasteType!,
        scheduledDate: "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        slot: _selectedSlot!,
        address: _addressController.text,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
      );
      
      final response = await repo.createPickup(request);
      setState(() {
        _result = response;
        _currentStep = 5; // Success Step
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e')),
        );
      }
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle(_currentStep)),
        leading: _currentStep > 1 && _currentStep < 5
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
            : null,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStepView(),
          ),
          if (_currentStep < 5) _buildBottomBar(),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 1: return 'Choose Waste Type';
      case 2: return 'Select Date';
      case 3: return 'Select Time Slot';
      case 4: return 'Confirm Location';
      case 5: return 'Booking Success';
      default: return 'Book Pickup';
    }
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: _currentStep / 5.0,
      backgroundColor: Colors.grey.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1: return _stepWasteType();
      case 2: return _stepDateSelection();
      case 3: return _stepSlotSelection();
      case 4: return _stepLocation();
      case 5: return _stepSuccess();
      default: return const SizedBox();
    }
  }

  // --- STEP 1: WASTE TYPE ---
  Widget _stepWasteType() {
    final isDesktop = GLResponsive.isDesktop(context);
    final isTablet = GLResponsive.isTablet(context);

    return GridView.count(
      crossAxisCount: isDesktop ? 6 : (isTablet ? 4 : 2),
      padding: const EdgeInsets.all(GLSpacing.xl),
      mainAxisSpacing: GLSpacing.lg,
      crossAxisSpacing: GLSpacing.lg,
      childAspectRatio: isDesktop ? 1.0 : 1.0,
      children: WasteType.values.map((type) {
        final isSelected = _selectedWasteType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedWasteType = type),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? type.color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(GLRadius.md),
              border: Border.all(
                color: isSelected ? type.color : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 48, color: type.color),
                const SizedBox(height: GLSpacing.md),
                Text(
                  type.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- STEP 2: DATE ---
  Widget _stepDateSelection() {
    if (_slots.isEmpty && !_isLoadingSlots) {
       _loadSlots();
    }
    
    if (_isLoadingSlots) return const Center(child: CircularProgressIndicator());

    // Group slots by date
    final dates = _slots.map((s) => s.date).toSet().toList();

    return ListView.builder(
      padding: const EdgeInsets.all(GLSpacing.xl),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dateStr = dates[index];
        final dt = DateTime.parse(dateStr);
        final isSelected = _selectedDate != null && _selectedDate!.day == dt.day && _selectedDate!.month == dt.month;

        return GLCard(
          margin: const EdgeInsets.only(bottom: GLSpacing.md),
          child: ListTile(
            title: Text("${dt.day} ${_monthName(dt.month)} ${dt.year}"),
            subtitle: Text(_weekday(dt.weekday)),
            trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
            onTap: () => setState(() => _selectedDate = dt),
          ),
        );
      },
    );
  }

  // --- STEP 3: SLOTS ---
  Widget _stepSlotSelection() {
    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final availableSlots = _slots.where((s) => s.date == dateStr).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(GLSpacing.xl),
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final slotObj = availableSlots[index];
        final isSelected = _selectedSlot == slotObj.slot;

        return GLCard(
          margin: const EdgeInsets.only(bottom: GLSpacing.md),
          child: ListTile(
            title: Text(slotObj.slot),
            enabled: slotObj.isAvailable,
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : (!slotObj.isAvailable ? const Text('Full') : null),
            onTap: slotObj.isAvailable ? () => setState(() => _selectedSlot = slotObj.slot) : null,
          ),
        );
      },
    );
  }

  // --- STEP 4: LOCATION ---
  Widget _stepLocation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GLRadius.md),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.map_rounded, size: 80, color: Colors.grey)),
                Positioned(
                  bottom: 12, right: 12,
                  child: FloatingActionButton.small(
                    onPressed: _handleLocationDetection,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GLSpacing.xl),
          GLTextField(
            label: 'Pickup Address',
            hint: 'Confirm your flat/house details',
            controller: _addressController,
            prefixIcon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
    );
  }

  // --- STEP 5: SUCCESS ---
  Widget _stepSuccess() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: GLSpacing.xl),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: GLSpacing.md),
            Text('Pickup ID: ${_result?.id}'),
            const SizedBox(height: GLSpacing.xxl),
            QrImageView(
              data: _result?.qrCodeData ?? '',
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: GLSpacing.xxl),
            GLButton(
              text: 'Finish',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(GLSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: GLButton(
        text: _currentStep == 4 ? 'Confirm Booking' : 'Next',
        isLoading: _isBooking,
        onPressed: _canGoNext() ? (_currentStep == 4 ? _confirmBooking : _nextStep) : null,
      ),
    );
  }

  bool _canGoNext() {
    if (_currentStep == 1) return _selectedWasteType != null;
    if (_currentStep == 2) return _selectedDate != null;
    if (_currentStep == 3) return _selectedSlot != null;
    if (_currentStep == 4) return _addressController.text.isNotEmpty;
    return true;
  }

  String _monthName(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m-1];
  String _weekday(int d) => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d-1];
}
