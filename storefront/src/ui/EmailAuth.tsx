import { useMembers, } from "./client";
import MemberRow from "./MemberRow";

import type { Member } from "../types/supabase";

const EmailAuth = ({ me, organizationId, }: { me: null | Member; organizationId: string; }) => {
  const { data: members, isLoading: membersLoading } = useMembers({
    enabled: true,
    organizationId,
    showEmails: true,
  });

  return (
    <>
      {membersLoading && (
        <div className="ml-4 mt-4 flex w-2/3 flex-col gap-4">
          <div className="skeleton h-4 w-full"></div>
          <div className="skeleton h-4 w-full"></div>
          <div className="skeleton h-4 w-full"></div>
        </div>
      )}
      {members && (
        <div className="text-gray-200 dark:text-gray-700 p-4 m-4 border border-zinc-500 rounded-lg text-sm">
          <div className="bg-dots rounded-2xl">
            {members.map(m => {
              return (
                <MemberRow m={m} me={me} key={m.user_id} verifyText="🙋 That’s me!" />
              );
            })}
          </div>
        </div>
      )}
    </>
  );
};

export default EmailAuth;
