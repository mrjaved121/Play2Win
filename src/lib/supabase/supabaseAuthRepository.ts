import { getSupabaseServerClient } from "@/lib/supabase/client";
import type { AdminUser } from "@/lib/types";
import type { AuthRepository } from "@/lib/repositories/types";

export const supabaseAuthRepository: AuthRepository = {
  async signIn(email: string, password: string): Promise<AdminUser | null> {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error || !data.user) return null;

    const { data: profile } = await supabase
      .from("admin_profiles")
      .select("name, role")
      .eq("user_id", data.user.id)
      .maybeSingle();

    if (!profile) {
      // Signed in via Supabase Auth but not provisioned as an admin.
      return null;
    }

    return {
      id: data.user.id,
      email: data.user.email ?? email,
      name: profile.name as string,
      role: profile.role as AdminUser["role"],
    };
  },
};
