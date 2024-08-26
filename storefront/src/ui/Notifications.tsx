import React from "react";

import SectionHeader from "./SectionHeader";
import MemberRow from "./MemberRow";
import { useQuery, useMutation } from "@tanstack/react-query";

import type { UserNotification } from "../types/z_types";

import { apiServer, queryClient, queryKeys, useMembers } from "./client";

import type { Organization, Member } from "../types/supabase";

const Notifications = ({ organization, me }: { organization: Organization; me: null | Member }) => {
  const { data: members, isLoading: membersLoading } = useMembers({
    enabled: !!organization,
    organizationId: organization.id as string,
    showEmails: true,
  });

  const {
    data: notifications,
    isFetching: notificationsFetching,
    isLoading: notificationsLoading,
    isPending: notificationsPending,
  } = useQuery({
    queryKey: queryKeys.notifications(organization.id),
    queryFn: async () => {
      return await apiServer.url(`/email-notifications`).get().json<UserNotification[]>();
    },
  });

  const notificationsInProgress =
    notificationsFetching || notificationsLoading || notificationsPending;

  const updateNotificationMutation = useMutation({
    mutationFn: ({ userId, txEmailsEnabled }: { userId: string; txEmailsEnabled: boolean }) => {
      return apiServer.url(`/email-notifications/${userId}`).post({ txEmailsEnabled }).text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.notifications(organization.id) });
      setClickedUserId(null);
    },
  });

  const [clickedUserId, setClickedUserId] = React.useState<null | string>(null);

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
      {(membersLoading || notificationsLoading) && (
        <div className="ml-4 mt-4 flex w-2/3 flex-col gap-4">
          <div className="skeleton h-4 w-full"></div>
          <div className="skeleton h-4 w-full"></div>
          <div className="skeleton h-4 w-full"></div>
        </div>
      )}
      {members && notifications && (
        <div className="text-gray-200 dark:text-gray-700 p-4 m-4 border border-zinc-500 rounded-lg text-sm">
          <div className="bg-dots rounded-2xl">
            {members.map(m => {
              const notification = notifications.find(n => n.user_id === m.user_id);
              return (
                <MemberRow m={m} me={me} key={m.user_id} verifyText="🙋 That’s me!">
                  {me && notifications ? (
                    clickedUserId === m.user_id &&
                    (updateNotificationMutation.isPending || notificationsInProgress) ? (
                      <span className="loading loading-ring loading-sm text-info h-3" />
                    ) : (
                      <input
                        type="checkbox"
                        onChange={e => {
                          setClickedUserId(m.user_id);
                          updateNotificationMutation.mutate({
                            userId: m.user_id,
                            txEmailsEnabled: e.target.checked,
                          });
                        }}
                        value={notification?.tx_emails ?? false ? "checked" : "not checked"}
                        disabled={
                          me.user_id !== m.user_id &&
                          !["Owner", "Administrator"].includes(me.role_name)
                        }
                        checked={notification?.tx_emails ?? false}
                        className="checkbox checkbox-info checkbox-sm"
                      />
                    )
                  ) : (
                    <></>
                  )}
                </MemberRow>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};

export default Notifications;
