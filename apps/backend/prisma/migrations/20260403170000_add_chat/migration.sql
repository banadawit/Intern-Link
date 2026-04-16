CREATE TABLE "ChatMessage" (
  "id"         SERIAL PRIMARY KEY,
  "senderId"   INTEGER NOT NULL,
  "receiverId" INTEGER NOT NULL,
  "content"    TEXT NOT NULL,
  "is_read"    BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ChatMessage_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "ChatMessage_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "ChatMessage_senderId_receiverId_created_at_idx" ON "ChatMessage"("senderId","receiverId","created_at");
CREATE INDEX "ChatMessage_receiverId_is_read_idx" ON "ChatMessage"("receiverId","is_read");
