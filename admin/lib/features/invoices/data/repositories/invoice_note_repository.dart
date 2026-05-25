import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_note.dart';

class InvoiceNoteRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'invoice_notes';

  InvoiceNoteRepository(this._firestore);

  // Get all notes for an invoice
  Stream<List<InvoiceNote>> getNotesForInvoice(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get all notes
  Stream<List<InvoiceNote>> getAllNotes() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get notes by type
  Stream<List<InvoiceNote>> getNotesByType(NoteType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get internal notes only
  Stream<List<InvoiceNote>> getInternalNotes(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .where('isInternal', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get customer-visible notes only
  Stream<List<InvoiceNote>> getCustomerNotes(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .where('isInternal', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get note by ID
  Future<InvoiceNote?> getNoteById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceNote.fromFirestore(doc);
  }

  // Create new note
  Future<InvoiceNote> createNote(InvoiceNote note) async {
    final docRef = await _firestore.collection(_collection).add(note.toFirestore());
    final doc = await docRef.get();
    return InvoiceNote.fromFirestore(doc);
  }

  // Update note
  Future<void> updateNote(InvoiceNote note) async {
    await _firestore
        .collection(_collection)
        .doc(note.id)
        .update(note.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  // Delete note
  Future<void> deleteNote(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Toggle pin status
  Future<void> togglePin(String id, bool isPinned) async {
    await _firestore.collection(_collection).doc(id).update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get notes with attachments
  Stream<List<InvoiceNote>> getNotesWithAttachments(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .where('attachmentUrl', isNotEqualTo: null)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get pinned notes
  Stream<List<InvoiceNote>> getPinnedNotes(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Search notes
  Stream<List<InvoiceNote>> searchNotes(String query) {
    return _firestore
        .collection(_collection)
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: '$query')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get note statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();
    final notes = snapshot.docs
        .map((doc) => InvoiceNote.fromFirestore(doc))
        .toList();

    final totalNotes = notes.length;
    final internalNotes = notes.where((n) => n.isInternal).length;
    final customerNotes = notes.where((n) => !n.isInternal).length;
    final pinnedNotes = notes.where((n) => n.isPinned).length;
    final notesWithAttachments = notes.where((n) => n.attachmentUrl != null).length;

    final typeCounts = <NoteType, int>{};
    for (final note in notes) {
      typeCounts[note.type] = (typeCounts[note.type] ?? 0) + 1;
    }

    return {
      'totalNotes': totalNotes,
      'internalNotes': internalNotes,
      'customerNotes': customerNotes,
      'pinnedNotes': pinnedNotes,
      'notesWithAttachments': notesWithAttachments,
      'typeCounts': typeCounts,
    };
  }

  // Get notes by user
  Stream<List<InvoiceNote>> getNotesByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }

  // Get notes mentioning a user
  Stream<List<InvoiceNote>> getNotesMentioningUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('mentionedUsers', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNote.fromFirestore(doc))
            .toList());
  }
}