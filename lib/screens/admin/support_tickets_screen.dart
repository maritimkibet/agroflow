import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/admin_user.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final AdminService _adminService = AdminService();
  
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;
  TicketStatus? _selectedStatus;
  TicketPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    
    try {
      final tickets = await _adminService.getSupportTickets(
        status: _selectedStatus,
        priority: _selectedPriority,
      );
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tickets: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Support Tickets',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadTickets,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              DropdownButton<TicketStatus?>(
                value: _selectedStatus,
                hint: const Text('All Statuses'),
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _loadTickets();
                },
                items: [
                  const DropdownMenuItem<TicketStatus?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  ...TicketStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(_formatStatus(status)),
                  )),
                ],
              ),
              const SizedBox(width: 16),
              DropdownButton<TicketPriority?>(
                value: _selectedPriority,
                hint: const Text('All Priorities'),
                onChanged: (value) {
                  setState(() => _selectedPriority = value);
                  _loadTickets();
                },
                items: [
                  const DropdownMenuItem<TicketPriority?>(
                    value: null,
                    child: Text('All Priorities'),
                  ),
                  ...TicketPriority.values.map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(_formatPriority(priority)),
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tickets List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tickets.isEmpty
                    ? const Center(child: Text('No tickets found'))
                    : Card(
                        child: ListView.builder(
                          itemCount: _tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _tickets[index];
                            return _buildTicketTile(ticket);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTile(SupportTicket ticket) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: _getPriorityColor(ticket.priority).withValues(alpha: 0.1),
        child: Icon(
          _getPriorityIcon(ticket.priority),
          color: _getPriorityColor(ticket.priority),
        ),
      ),
      title: Text(
        ticket.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From: ${ticket.userName}'),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildStatusChip(
                _formatStatus(ticket.status),
                color: _getStatusColor(ticket.status),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                _formatPriority(ticket.priority),
                color: _getPriorityColor(ticket.priority),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(ticket.category),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Created: ${_formatDateTime(ticket.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleTicketAction(ticket, action),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'assign',
            child: Row(
              children: [
                Icon(Icons.assignment_ind),
                SizedBox(width: 8),
                Text('Assign to Me'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'in_progress',
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.blue),
                SizedBox(width: 8),
                Text('Mark In Progress'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'resolved',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Mark Resolved'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'escalate',
            child: Row(
              children: [
                Icon(Icons.priority_high, color: Colors.red),
                SizedBox(width: 8),
                Text('Escalate'),
              ],
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(ticket.description),
              const SizedBox(height: 16),
              
              if (ticket.assignedTo != null) ...[
                Text(
                  'Assigned to: ${ticket.assignedTo}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
              ],
              
              if (ticket.tags.isNotEmpty) ...[
                const Text(
                  'Tags:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ticket.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey.shade200,
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showTicketDetails(ticket),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Full Details'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _contactUser(ticket),
                    icon: const Icon(Icons.message),
                    label: const Text('Contact User'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? Colors.blue).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleTicketAction(SupportTicket ticket, String action) async {
    switch (action) {
      case 'assign':
        final success = await _adminService.assignTicket(
          ticket.id,
          _adminService.currentAdmin!.id,
        );
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket assigned successfully')),
          );
          _loadTickets();
        }
        break;
      case 'in_progress':
        await _updateTicketStatus(ticket, TicketStatus.inProgress);
        break;
      case 'resolved':
        await _updateTicketStatus(ticket, TicketStatus.resolved);
        break;
      case 'escalate':
        await _updateTicketStatus(ticket, TicketStatus.escalated);
        break;
    }
  }

  Future<void> _updateTicketStatus(SupportTicket ticket, TicketStatus status) async {
    final success = await _adminService.updateTicketStatus(ticket.id, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket status updated to ${_formatStatus(status)}')),
      );
      _loadTickets();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update ticket status')),
      );
    }
  }

  void _showTicketDetails(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket #${ticket.id.substring(0, 8)}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Title', ticket.title),
                _buildDetailRow('User', ticket.userName),
                _buildDetailRow('Category', ticket.category),
                _buildDetailRow('Priority', _formatPriority(ticket.priority)),
                _buildDetailRow('Status', _formatStatus(ticket.status)),
                _buildDetailRow('Created', _formatDateTime(ticket.createdAt)),
                _buildDetailRow('Updated', _formatDateTime(ticket.updatedAt)),
                if (ticket.assignedTo != null)
                  _buildDetailRow('Assigned To', ticket.assignedTo!),
                const SizedBox(height: 16),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(ticket.description),
                if (ticket.metadata.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Additional Information:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...ticket.metadata.entries.map((entry) =>
                    _buildDetailRow(entry.key, entry.value.toString())),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _contactUser(SupportTicket ticket) {
    // Implement user contact functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${ticket.userName}'),
        content: const Text('Contact functionality coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatStatus(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
      case TicketStatus.escalated:
        return 'Escalated';
    }
  }

  String _formatPriority(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
      case TicketStatus.escalated:
        return Colors.red;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.green;
      case TicketPriority.medium:
        return Colors.orange;
      case TicketPriority.high:
        return Colors.red;
      case TicketPriority.urgent:
        return Colors.purple;
    }
  }

  IconData _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Icons.low_priority;
      case TicketPriority.medium:
        return Icons.remove;
      case TicketPriority.high:
        return Icons.priority_high;
      case TicketPriority.urgent:
        return Icons.warning;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}