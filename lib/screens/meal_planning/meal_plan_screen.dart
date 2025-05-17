import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/models/meal_plan_model.dart';
import 'package:recipe_cart/services/meal_plan_service.dart';
import 'package:recipe_cart/services/shopping_list_service.dart';
import 'package:recipe_cart/widgets/meal_plan_card.dart';
import 'package:recipe_cart/screens/meal_planning/add_meal_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  MealPlan? _selectedDayMealPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadMealPlanForSelectedDay();
  }

  void _loadMealPlanForSelectedDay() async {
    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<UserModel>(context, listen: false);
    final mealPlanService = Provider.of<MealPlanService>(context, listen: false);

    try {
      final mealPlan = await mealPlanService.getMealPlanForDate(
        user.uid,
        _selectedDay,
      );

      setState(() {
        _selectedDayMealPlan = mealPlan;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meal plan: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadMealPlanForSelectedDay();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final mealPlanService = Provider.of<MealPlanService>(context);
    final shoppingListService = Provider.of<ShoppingListService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Generate shopping list',
            onPressed: () async {
              // Show date range picker for shopping list generation
              final DateTimeRange? dateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                initialDateRange: DateTimeRange(
                  start: _selectedDay,
                  end: _selectedDay.add(const Duration(days: 7)),
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).colorScheme.primary,
                        onPrimary: Theme.of(context).colorScheme.onPrimary,
                        onSurface: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (dateRange != null) {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating shopping list...'),
                      ],
                    ),
                  ),
                );

                try {
                  // Use generateShoppingListFromMealPlan with the correct parameters
                  await mealPlanService.generateShoppingListFromMealPlan(
                    userId: user.uid,
                    startDate: dateRange.start,
                    endDate: dateRange.end,
                  );

                  // Close loading dialog
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Shopping list generated for ${DateFormat('MMM d').format(dateRange.start)} - ${DateFormat('MMM d').format(dateRange.end)}',
                      ),
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'View',
                        onPressed: () {
                          // Navigate to shopping list screen
                          Navigator.pushNamed(context, '/shopping');
                        },
                      ),
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error generating shopping list: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.week,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          const Divider(),

          // Meal plan for selected day
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMealPlanContent(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add meal screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMealScreen(selectedDate: _selectedDay),
            ),
          );

          // Reload meal plan if a meal was added
          if (result == true) {
            _loadMealPlanForSelectedDay();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add meal',
      ),
    );
  }

  Widget _buildMealPlanContent(BuildContext context) {
    if (_selectedDayMealPlan == null || _selectedDayMealPlan!.meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No meals planned for ${DateFormat('EEEE, MMMM d').format(_selectedDay)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add meals',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final user = Provider.of<UserModel>(context);
    final mealPlanService = Provider.of<MealPlanService>(context);

    // Group meals by meal type (breakfast, lunch, dinner, snack)
    final mealsByType = <String, List<MealEntry>>{};

    for (final meal in _selectedDayMealPlan!.meals) {
      if (!mealsByType.containsKey(meal.mealType)) {
        mealsByType[meal.mealType] = [];
      }
      mealsByType[meal.mealType]!.add(meal);
    }

    // Sort meal types in logical order
    final mealTypes = mealsByType.keys.toList();
    mealTypes.sort((a, b) {
      final order = {'breakfast': 0, 'lunch': 1, 'dinner': 2, 'snack': 3};
      return (order[a.toLowerCase()] ?? 4).compareTo(order[b.toLowerCase()] ?? 4);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final mealType in mealTypes) ...[
          Text(
            mealType.substring(0, 1).toUpperCase() + mealType.substring(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final meal in mealsByType[mealType]!) ...[
            MealPlanCard(
              mealEntry: meal,
              onDelete: () async {
                // Show confirmation dialog
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove meal?'),
                    content: Text(
                      'Are you sure you want to remove ${meal.recipeName} from your meal plan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  // Use removeMealFromMealPlan instead of removeMealFromPlan
                  await mealPlanService.removeMealFromMealPlan(
                    userId: user.uid,
                    mealPlanId: _selectedDayMealPlan!.id,
                    mealEntryId: meal.id,
                  );
                  _loadMealPlanForSelectedDay();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
          const Divider(),
        ],
      ],
    );
  }
}