"use client";

import { useEffect, useState, useRef } from "react";
import { apiClient } from "@/lib/api-client";
import { MessageCircle, Send, Loader2 } from "lucide-react";
import { useAuth } from "@/features/auth/auth-context";

interface PlanMessage {
  id: number;
  plan_id: number;
  user_id: number;
  body: string;
  created_at: string;
  user: {
    id: number;
    name: string;
    handle: string | null;
  };
}

interface PlanChatWidgetProps {
  planId: number;
}

export function PlanChatWidget({ planId }: PlanChatWidgetProps) {
  const { user } = useAuth();
  const [messages, setMessages] = useState<PlanMessage[]>([]);
  const [newMessage, setNewMessage] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const chatContainerRef = useRef<HTMLDivElement>(null);
  const isFirstLoad = useRef(true);

  const scrollToBottomInternal = () => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  };

  const fetchMessages = async (showLoading = false) => {
    if (showLoading) setIsLoading(true);
    try {
      const res = await apiClient.get<{ data: PlanMessage[] }>(`/plans/${planId}/messages`);
      setMessages(res.data);
    } catch (err) {
      console.error("Failed to fetch messages:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    isFirstLoad.current = true;
    fetchMessages(true);

    const interval = setInterval(() => {
      fetchMessages(false);
    }, 5000);

    return () => clearInterval(interval);
  }, [planId]);

  useEffect(() => {
    if (messages.length > 0 && isFirstLoad.current) {
      isFirstLoad.current = false;
      scrollToBottomInternal();
    }
  }, [messages]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || isSubmitting) return;

    const optimisticMessage: PlanMessage = {
      id: Date.now(), // Temporary ID
      plan_id: planId,
      user_id: user?.id || 0,
      body: newMessage,
      created_at: new Date().toISOString(),
      user: {
        id: user?.id || 0,
        name: user?.name || "Me",
        handle: user?.handle || null,
      },
    };

    setMessages((prev) => [...prev, optimisticMessage]);
    setNewMessage("");
    setIsSubmitting(true);
    setTimeout(scrollToBottomInternal, 50);

    try {
      await apiClient.post(`/plans/${planId}/messages`, { body: optimisticMessage.body });
      await fetchMessages(false);
      setTimeout(scrollToBottomInternal, 50);
    } catch (err: any) {
      console.error("Failed to send message", err);
      // Revert optimistic update
      setMessages((prev) => prev.filter((m) => m.id !== optimisticMessage.id));
      alert("Failed to send message: " + (err.message || "Unknown error"));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl flex flex-col shadow-xs h-[500px]">
      <div className="p-4 border-b border-[#E8E5DF] flex items-center gap-2">
        <MessageCircle className="w-5 h-5 text-[#2B7A72]" />
        <h3 className="font-bold text-[#1F2223]">Plan Discussion</h3>
      </div>

      <div ref={chatContainerRef} className="flex-1 overflow-y-auto p-4 space-y-4 bg-[#FAF9F6]">
        {isLoading ? (
          <div className="flex justify-center py-4">
            <Loader2 className="w-5 h-5 text-[#959A9E] animate-spin" />
          </div>
        ) : messages.length === 0 ? (
          <div className="text-center text-xs text-[#959A9E] py-8">
            No messages yet. Start the conversation!
          </div>
        ) : (
          messages.map((msg) => {
            const isMe = msg.user.id === user?.id;
            return (
              <div key={msg.id} className={`flex flex-col ${isMe ? "items-end" : "items-start"}`}>
                <div className="flex items-baseline gap-2 mb-1">
                  <span className="text-[10px] font-bold text-[#656A6D]">
                    {isMe ? "You" : msg.user.name.split(" ")[0]}
                  </span>
                  <span className="text-[9px] text-[#959A9E]">
                    {new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
                <div
                  className={`px-3 py-2 rounded-2xl text-xs max-w-[85%] break-words ${
                    isMe
                      ? "bg-[#2B7A72] text-white rounded-br-sm"
                      : "bg-white border border-[#E8E5DF] text-[#1F2223] rounded-bl-sm"
                  }`}
                >
                  {msg.body}
                </div>
              </div>
            );
          })
        )}
      </div>

      <div className="p-3 bg-white border-t border-[#E8E5DF] rounded-b-2xl">
        <form onSubmit={handleSubmit} className="flex items-center gap-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="Type a message..."
            maxLength={1000}
            className="flex-1 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-[#81D8D0] transition-colors"
          />
          <button
            type="submit"
            disabled={!newMessage.trim() || isSubmitting}
            className="p-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl transition-colors disabled:opacity-50"
          >
            <Send className="w-4 h-4" />
          </button>
        </form>
      </div>
    </div>
  );
}
