export type AiWeeklyPlanResponse = {
  success: boolean;
  data?: {
    tasks: string;
    goals: string;
    deliverables: string;
  };
  message?: string;
};

export type AiFeedbackResponse = {
  success: boolean;
  data?: {
    strengths: string;
    weaknesses: string;
    suggestions: string;
  };
  message?: string;
};

export type AiChatResponse = {
  success: boolean;
  data?: {
    reply: string;
  };
  /** Mirror of data.reply from API */
  reply?: string;
  message?: string;
};

export type AiChatHistoryApiResponse = {
  success: boolean;
  data?: {
    messages: { role: 'user' | 'assistant'; content: string }[];
  };
  message?: string;
};
