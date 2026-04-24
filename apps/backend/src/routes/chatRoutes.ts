import { Router } from 'express';
import { authenticate } from '../middlewares/authMiddleware';
import * as chat from '../controllers/chatController';

const router = Router();
router.use(authenticate);

router.get('/contacts', chat.getContacts);
router.get('/conversations', chat.getConversations);
router.get('/unread-count', chat.getUnreadCount);
router.delete('/history/:userId', chat.deleteConversation);
router.get('/:userId', chat.getMessages);
router.post('/:userId', chat.sendMessage);

export default router;
