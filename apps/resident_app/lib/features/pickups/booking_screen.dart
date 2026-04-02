import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'package:core/core.dart';
import 'package:geo/geo.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

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

  // Cache/Data
  List<PickupSlot> _slotTemplates = [];
  List<PickupSlot> _availabilityForDate = [];
  bool _isLoadingInitial = false;
  bool _isLoadingAvailability = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _nextStep() => setState(() => _currentStep++);
  void _prevStep() => setState(() => _currentStep--);

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingInitial = true);
    try {
      final pickupRepo = Provider.of<PickupRepository>(context, listen: false);
      final rewardRepo = Provider.of<RewardRepository>(context, listen: false);
      
      final profile = await rewardRepo.getProfile();
      final templates = await pickupRepo.getPickupSlots(profile.wardId);
      
      setState(() {
        _slotTemplates = templates;
        _isLoadingInitial = false;
        if (_addressController.text.isEmpty) {
          _addressController.text = profile.address;
          _latitude = profile.latitude;
          _longitude = profile.longitude;
        }
      });
    } catch (e) {
      debugPrint('Initial load error: $e');
      setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _onDateSelected(DateTime dt) async {
    setState(() {
      _selectedDate = dt;
      _isLoadingAvailability = true;
      _selectedSlot = null;
    });

    try {
      final pickupRepo = Provider.of<PickupRepository>(context, listen: false);
      final rewardRepo = Provider.of<RewardRepository>(context, listen: false);
      final profile = await rewardRepo.getProfile();
      
      final dateStr = DateFormat('yyyy-MM-dd').format(dt);
      final availability = await pickupRepo.getAvailability(dateStr, profile.wardId);
      
      setState(() {
        _availabilityForDate = availability;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      debugPrint('Availability error: $e');
      // If endpoint fails, fallback to templates but mark them as pending
      setState(() {
        _availabilityForDate = _slotTemplates;
        _isLoadingAvailability = false;
      });
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
        scheduledDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        slot: _selectedSlot!,
        address: _addressController.text,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
      );
      
      final response = await repo.createPickup(request);
      setState(() {
        _result = response;
        _currentStep = 5; 
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
          Expanded(child: _buildCurrentStepView()),
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
    if (_isLoadingInitial) return const Center(child: CircularProgressIndicator());
    switch (_currentStep) {
      case 1: return _stepWasteType();
      case 2: return _stepDateSelection();
      case 3: return _stepSlotSelection();
      case 4: return _stepLocation();
      case 5: return _stepSuccess();
      default: return const SizedBox();
    }
  }

  Widget _stepWasteType() {
    return GridView.count(
      crossAxisCount: GLResponsive.isMobile(context) ? 2 : 4,
      padding: const EdgeInsets.all(GLSpacing.xl),
      mainAxisSpacing: GLSpacing.lg,
      crossAxisSpacing: GLSpacing.lg,
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
                Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stepDateSelection() {
    // Generate next 7 days
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i + 1)));

    return ListView.builder(
      padding: const EdgeInsets.all(GLSpacing.xl),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dt = dates[index];
        final isSelected = _selectedDate != null && 
            _selectedDate!.year == dt.year &&
            _selectedDate!.month == dt.month &&
            _selectedDate!.day == dt.day;

        return GLCard(
          margin: const EdgeInsets.only(bottom: GLSpacing.md),
          child: ListTile(
            title: Text(DateFormat('EEEE, MMM d').format(dt)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
            onTap: () => _onDateSelected(dt),
          ),
        );
      },
    );
  }

  Widget _stepSlotSelection() {
    if (_isLoadingAvailability) return const Center(child: CircularProgressIndicator());

    final slotsToShow = _availabilityForDate.isNotEmpty ? _availabilityForDate : _slotTemplates;

    if (slotsToShow.isEmpty) {
      return const Center(child: Text('No slots configured for this ward.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(GLSpacing.xl),
      itemCount: slotsToShow.length,
      itemBuilder: (context, index) {
        final slotObj = slotsToShow[index];
        final isSelected = _selectedSlot == slotObj.id;

        return GLCard(
          margin: const EdgeInsets.only(bottom: GLSpacing.md),
          child: ListTile(
            title: Text(slotObj.slot),
            enabled: slotObj.isAvailable,
            trailing: isSelected 
                ? const Icon(Icons.check_circle, color: Colors.green) 
                : (!slotObj.isAvailable ? const Text('Full', style: TextStyle(color: Colors.red)) : null),
            onTap: slotObj.isAvailable ? () => setState(() => _selectedSlot = slotObj.id) : null,
          ),
        );
      },
    );
  }

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

  Widget _stepSuccess() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GLSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: GLSpacing.xl),
            const Text('Booking Confirmed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: GLSpacing.md),
            Text('Pickup ID: ${_result?.id}'),
            const SizedBox(height: GLSpacing.xxl),
            if (_result?.qrCodeData != null)
              QrImageView(
                data: _result!.qrCodeData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            const SizedBox(height: GLSpacing.xxl),
            GLButton(text: 'Finish', onPressed: () => Navigator.pop(context)),
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
}
