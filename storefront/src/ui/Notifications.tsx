import SectionHeader from "./SectionHeader";
import MemberRow from "./MemberRow";
import { useQuery } from "@tanstack/react-query";

import type { UserNotification } from "../types/z_types";

import { apiServer, useMembers, queryKeys } from "./client";

import type { Organization, Member } from "../types/supabase";

const Notifications = ({ organization, me }: { organization: Organization; me: null | Member }) => {
  const { data: members, isLoading: membersLoading } = useMembers({
    enabled: !!organization,
    organizationId: organization.id as string,
    showEmails: true,
  });

  const { data: notifications, isLoading: notificationsLoading } = useQuery({
    queryKey: queryKeys.notifications(organization.id),
    queryFn: async () => {
      return await apiServer.url(`/email-notifications`).get().json<UserNotification[]>();
    },
  });

  return (
    <div className="self-start w-full">
      <SectionHeader text="Who should get email notifications from Supafana?">
        <>
          {!me && (
            <div className="text-sm text-gray-500 font-medium">
              Please verify your email below to configure
            </div>
          )}
        </>
      </SectionHeader>
      {membersLoading && (
        <div className="flex w-52 flex-col gap-4">
          <div className="skeleton h-4 w-full"></div>
          <div className="skeleton h-4 w-full"></div>
          <div className="skeleton h-4 w-full"></div>
        </div>
      )}
      {members && (
        <div className="mt-4 mx-4 p-4 border border-zinc-500 rounded-lg">
          <table className="text-gray-200 dark:text-gray-700 bg-dots table">
            <tbody>
              {members.map(m => {
                return (
                  <MemberRow m={m} me={me} key={m.user_id} verifyText="🙋 That’s me!">
                    {me ? (
                      <input
                        type="checkbox"
                        onChange={() => {}}
                        value={me.email || m.email ? "checked" : "not checked"}
                        disabled={
                          me.user_id !== m.user_id &&
                          !["Owner", "Administrator"].includes(me.role_name)
                        }
                        checked={me?.email || m.email ? true : false}
                        className="checkbox checkbox-info checkbox-sm"
                      />
                    ) : (
                      <></>
                    )}
                  </MemberRow>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default Notifications;
