import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/localizations.dart';
import '../../shared/models/app_entry.dart';
import '../../shared/pages/data_management_page.dart';
import '../../shared/services/app_help_service.dart';
import '../../shared/services/app_switcher_service.dart';
import '../../shared/services/locale_provider.dart';
import '../services/notifications_service.dart';
import '../models/app_notification.dart';

class _NotificationFormResult {
  final String title;
  final String body;
  final NotificationScheduleType scheduleType;
  final TimeOfDay time;
  final Set<int> weekdays;
  final bool enabled;

  const _NotificationFormResult({
    required this.title,
    required this.body,
    required this.scheduleType,
    required this.time,
    required this.weekdays,
    required this.enabled,
  });
}

class NotificationsHome extends StatefulWidget {
  final VoidCallback? onAppSwitched;

  const NotificationsHome({super.key, this.onAppSwitched});

  @override
  State<NotificationsHome> createState() => _NotificationsHomeState();
}

class _NotificationsHomeState extends State<NotificationsHome> {
  @override
  void initState() {
    super.initState();
    // Ensure box is opened so the page can render existing notifications.
    NotificationsService.openBox();
  }

  void _changeLanguage(String langCode) {
    final localeProvider = Modular.get<LocaleProvider>();
    localeProvider.changeLocale(Locale(langCode));
  }

  void _openDataManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DataManagementPage(),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showAppSwitcher() async {
    final apps = AvailableApps.getAll(context);
    final currentAppId = AppSwitcherService.getSelectedAppId();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          t(context, 'select_app'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: apps.map((app) {
              final isSelected = app.id == currentAppId;
              return InkWell(
                onTap: () async {
                  if (app.id != currentAppId) {
                    await AppSwitcherService.setSelectedAppId(app.id);
                    if (!mounted) return;
                    widget.onAppSwitched?.call();
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          app.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : null,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t(context, 'close')),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelp() async {
    AppHelpService.showHelpDialog(context, AvailableApps.notifications);
  }

  Future<void> _createNotification() async {
    final result = await _openNotificationEditor();
    if (result == null) return;

    final timeMinutes = result.time.hour * 60 + result.time.minute;
    final notification = AppNotification(
      notificationId: NotificationsService.generateNotificationId(),
      title: result.title.trim(),
      body: result.body.trim(),
      enabled: result.enabled,
      scheduleType: result.scheduleType,
      timeMinutes: timeMinutes,
      weekdays: result.weekdays.toList()..sort(),
    );

    await NotificationsService.upsert(notification);
  }

  Future<void> _editNotification(AppNotification existing) async {
    final initialTime = TimeOfDay(
      hour: existing.timeMinutes ~/ 60,
      minute: existing.timeMinutes % 60,
    );

    final result = await _openNotificationEditor(
      initial: _NotificationFormResult(
        title: existing.title,
        body: existing.body,
        scheduleType: existing.scheduleType,
        time: initialTime,
        weekdays: existing.weekdays.toSet(),
        enabled: existing.enabled,
      ),
    );
    if (result == null) return;

    final timeMinutes = result.time.hour * 60 + result.time.minute;
    final updated = existing.copyWith(
      title: result.title.trim(),
      body: result.body.trim(),
      enabled: result.enabled,
      scheduleType: result.scheduleType,
      timeMinutes: timeMinutes,
      weekdays: result.weekdays.toList()..sort(),
    );

    await NotificationsService.upsert(updated);
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          t(context, 'notifications_delete_title'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Text(t(context, 'notifications_delete_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              t(context, 'delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await NotificationsService.delete(notification);
  }

  String _formatTime(BuildContext context, int timeMinutes) {
    final tod = TimeOfDay(hour: timeMinutes ~/ 60, minute: timeMinutes % 60);
    return MaterialLocalizations.of(context).formatTimeOfDay(tod);
  }

  String _weekdayLabel(BuildContext context, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return t(context, 'weekday_mon');
      case DateTime.tuesday:
        return t(context, 'weekday_tue');
      case DateTime.wednesday:
        return t(context, 'weekday_wed');
      case DateTime.thursday:
        return t(context, 'weekday_thu');
      case DateTime.friday:
        return t(context, 'weekday_fri');
      case DateTime.saturday:
        return t(context, 'weekday_sat');
      case DateTime.sunday:
        return t(context, 'weekday_sun');
      default:
        return weekday.toString();
    }
  }

  String _scheduleSummary(BuildContext context, AppNotification n) {
    final time = _formatTime(context, n.timeMinutes);
    if (n.scheduleType == NotificationScheduleType.daily) {
      return '${t(context, 'notifications_schedule_daily')} · $time';
    }

    final days = (n.weekdays.toList()..sort()).map((d) => _weekdayLabel(context, d)).join(', ');
    return '${t(context, 'notifications_schedule_weekly')} · $days · $time';
  }

  Future<_NotificationFormResult?> _openNotificationEditor({
    _NotificationFormResult? initial,
  }) async {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: initial?.title ?? '');
    final bodyController = TextEditingController(text: initial?.body ?? '');
    var scheduleType = initial?.scheduleType ?? NotificationScheduleType.daily;
    var time = initial?.time ?? const TimeOfDay(hour: 8, minute: 0);
    final weekdays = (initial?.weekdays.toSet() ?? <int>{});
    var enabled = initial?.enabled ?? true;

    bool isValid() {
      if (titleController.text.trim().isEmpty) return false;
      if (scheduleType == NotificationScheduleType.weekly && weekdays.isEmpty) return false;
      return true;
    }

    final result = await showDialog<_NotificationFormResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: time,
              );
              if (picked == null) return;
              setDialogState(() {
                time = picked;
              });
            }

            Widget weekdayChip(int weekday) {
              final selected = weekdays.contains(weekday);
              return FilterChip(
                selected: selected,
                label: Text(_weekdayLabel(context, weekday)),
                onSelected: (v) {
                  setDialogState(() {
                    if (v) {
                      weekdays.add(weekday);
                    } else {
                      weekdays.remove(weekday);
                    }
                  });
                },
              );
            }

            return AlertDialog(
              title: Text(
                initial == null
                    ? t(context, 'notifications_add_title')
                    : t(context, 'notifications_edit_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: t(context, 'notifications_field_title'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bodyController,
                      decoration: InputDecoration(
                        labelText: t(context, 'notifications_field_body'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<NotificationScheduleType>(
                      key: ValueKey<NotificationScheduleType>(scheduleType),
                      initialValue: scheduleType,
                      decoration: InputDecoration(
                        labelText: t(context, 'notifications_field_schedule'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: NotificationScheduleType.daily,
                          child: Text(t(context, 'notifications_schedule_daily')),
                        ),
                        DropdownMenuItem(
                          value: NotificationScheduleType.weekly,
                          child: Text(t(context, 'notifications_schedule_weekly')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          scheduleType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          '${t(context, 'notifications_field_time')}: ${MaterialLocalizations.of(context).formatTimeOfDay(time)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (scheduleType == NotificationScheduleType.weekly) ...[
                      Text(
                        t(context, 'notifications_field_weekdays'),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          weekdayChip(DateTime.monday),
                          weekdayChip(DateTime.tuesday),
                          weekdayChip(DateTime.wednesday),
                          weekdayChip(DateTime.thursday),
                          weekdayChip(DateTime.friday),
                          weekdayChip(DateTime.saturday),
                          weekdayChip(DateTime.sunday),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t(context, 'notifications_field_enabled')),
                      value: enabled,
                      onChanged: (v) {
                        setDialogState(() {
                          enabled = v;
                        });
                      },
                    ),
                    if (!isValid()) ...[
                      const SizedBox(height: 8),
                      Text(
                        scheduleType == NotificationScheduleType.weekly && weekdays.isEmpty
                            ? t(context, 'notifications_validation_weekdays')
                            : t(context, 'notifications_validation_title'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t(context, 'cancel')),
                ),
                TextButton(
                  onPressed: isValid()
                      ? () {
                          Navigator.of(dialogContext).pop(
                            _NotificationFormResult(
                              title: titleController.text,
                              body: bodyController.text,
                              scheduleType: scheduleType,
                              time: time,
                              weekdays: weekdays,
                              enabled: enabled,
                            ),
                          );
                        }
                      : null,
                  child: Text(t(context, 'save')),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    bodyController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'notifications_title')),
        actions: [
          IconButton(
            tooltip: t(context, 'switch_app'),
            icon: const Icon(Icons.grid_view),
            onPressed: _showAppSwitcher,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Text(t(context, 'lang_english')),
              ),
              PopupMenuItem(
                value: 'da',
                child: Text(t(context, 'lang_danish')),
              ),
            ],
          ),
          IconButton(
            tooltip: t(context, 'help'),
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
          IconButton(
            tooltip: t(context, 'data_management'),
            icon: const Icon(Icons.storage),
            onPressed: _openDataManagement,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNotification,
        tooltip: t(context, 'notifications_add'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: NotificationsService.openBox(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder(
            valueListenable: NotificationsService.box.listenable(),
            builder: (context, Box<AppNotification> box, _) {
              final items = box.values.toList()
                ..sort((a, b) => b.lastModified.compareTo(a.lastModified));

              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t(context, 'notifications_empty_title'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(context, 'notifications_empty_body'),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _createNotification,
                                icon: const Icon(Icons.add),
                                label: Text(t(context, 'notifications_add')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final n = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: n.enabled,
                                onChanged: (value) async {
                                  await NotificationsService.upsert(
                                    n.copyWith(enabled: value),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(
                            _scheduleSummary(context, n),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (n.body.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              n.body,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _editNotification(n),
                                icon: const Icon(Icons.edit),
                                label: Text(t(context, 'edit')),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _deleteNotification(n),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(
                                  t(context, 'delete'),
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
