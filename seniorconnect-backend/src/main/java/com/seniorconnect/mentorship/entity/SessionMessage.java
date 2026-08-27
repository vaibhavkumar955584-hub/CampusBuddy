package com.seniorconnect.mentorship.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "mentorship_session_messages")
public class SessionMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private MentorshipSession session;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @Column(nullable = false, length = 4000)
    private String messageContent;

    private boolean isEncrypted = false;

    private Instant createdAt = Instant.now();

    public SessionMessage() {}

    public SessionMessage(MentorshipSession session, User sender, String messageContent) {
        this.session = session;
        this.sender = sender;
        this.messageContent = messageContent;
        this.isEncrypted = false;
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public MentorshipSession getSession() { return session; }
    public void setSession(MentorshipSession session) { this.session = session; }
    public User getSender() { return sender; }
    public void setSender(User sender) { this.sender = sender; }
    public String getMessageContent() { return messageContent; }
    public void setMessageContent(String messageContent) { this.messageContent = messageContent; }
    public boolean isEncrypted() { return isEncrypted; }
    public void setEncrypted(boolean encrypted) { isEncrypted = encrypted; }
    public Instant getCreatedAt() { return createdAt; }
}
