import 'package:epi_gest_project/ui/config/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class PerfilWidget extends StatefulWidget {
  const PerfilWidget({super.key});

  @override
  State<PerfilWidget> createState() => _PerfilWidgetState();
}

class _PerfilWidgetState extends State<PerfilWidget> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return Card.outlined(
      child: MenuAnchor(
        builder: (context, controller, child) {
          return InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.purple.shade100,
                    child: Text(
                      'WG', // Iniciais do usuário
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'William Geralde', // Nome do usuário
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Administrador', // Cargo do usuário
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          );
        },
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.person_outline),
            child: const Text('Meu Perfil'),
            onPressed: () {},
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.notifications_outlined),
            child: const Text('Notificações'),
            onPressed: () {},
          ),
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.light_mode_outlined),
                trailingIcon: themeNotifier.themeOption == ThemeOption.light
                    ? const Icon(Icons.check, size: 18)
                    : null,
                child: const Text('Claro'),
                onPressed: () {
                  themeNotifier.setTheme(ThemeOption.light);
                },
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.dark_mode_outlined),
                trailingIcon: themeNotifier.themeOption == ThemeOption.dark
                    ? const Icon(Icons.check, size: 18)
                    : null,
                child: const Text('Escuro'),
                onPressed: () {
                  themeNotifier.setTheme(ThemeOption.dark);
                },
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.computer_outlined),
                trailingIcon: themeNotifier.themeOption == ThemeOption.system
                    ? const Icon(Icons.check, size: 18)
                    : null,
                child: const Text('Sistema'),
                onPressed: () {
                  themeNotifier.setTheme(ThemeOption.system);
                },
              ),
            ],
            leadingIcon: Icon(_getThemeIcon(themeNotifier.themeOption)),
            child: const Text('Escolher Tema'),
          ),
          const Divider(),
          MenuItemButton(
            leadingIcon: const Icon(Icons.logout, color: Colors.red),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeOption option) {
    switch (option) {
      case ThemeOption.light:
        return Icons.light_mode;
      case ThemeOption.dark:
        return Icons.dark_mode;
      case ThemeOption.system:
        return Icons.computer;
    }
  }
}
