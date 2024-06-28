export type Icon = React.FC<{
  height?: string;
  width?: string;
  className?: string;
  solidColor?: string;
  strokeWidth?: string;
  ariaLabel?: string;
  disabled?: boolean;
}>;
const defaultClassName = "w-3.5";

export const Facebook: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 25"
      fill="none"
    >
      <path
        d="M0 12.3406C0 5.71316 5.37258 0.340576 12 0.340576C18.6274 0.340576 24 5.71316 24 12.3406C24 18.968 18.6274 24.3406 12 24.3406C5.37258 24.3406 0 18.968 0 12.3406Z"
        fill="currentcolor"
      />
      <path
        d="M13.2503 19.3963V12.8677H15.0525L15.2913 10.6179H13.2503L13.2534 9.49183C13.2534 8.90505 13.3091 8.59063 14.1519 8.59063H15.2786V6.34058H13.4761C11.3111 6.34058 10.5491 7.43197 10.5491 9.26736V10.6181H9.19952V12.8679H10.5491V19.3963H13.2503Z"
        fill="white"
      />
    </svg>
  );
};

export const FogbenderText: Icon = ({ width = "198", height = "41", className = "" }) => {
  return (
    <svg
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      width={width}
      height={height}
      viewBox="0 0 198 41"
      fill="none"
      aria-label="fogbender"
    >
      <path
        d="M0.115234 2.01639H21.0743L21.4773 10.4H20.7518C19.7576 7.49798 18.6022 5.523 17.2855 4.47505C15.9957 3.42709 14.061 2.90312 11.4815 2.90312H10.3529V16.0025H12.1667C13.4565 16.0025 14.5313 15.5323 15.3911 14.5918C16.251 13.6513 16.8422 12.3616 17.1646 10.7225H17.7692V22.653H17.084C16.6541 20.6377 16.0495 19.2001 15.2702 18.3403C14.5178 17.4804 13.4833 17.0505 12.1667 17.0505H10.3529V29.3437H15.3508V30.2305H0.115234V29.3437H2.49328V2.90312H0.115234V2.01639Z"
        fill="black"
      />
      <path
        d="M34.5361 22.2902V18.8642C34.5361 16.2578 34.3883 14.3634 34.0927 13.1811C33.824 11.9719 33.1791 11.3673 32.158 11.3673C31.5669 11.3673 31.0832 11.542 30.707 11.8913C30.3577 12.2138 30.1025 12.7646 29.9412 13.5439C29.6994 14.753 29.5785 16.5937 29.5785 19.0658V22.2096C29.5785 25.1385 29.6591 26.8985 29.8203 27.4897C30.0084 28.0808 30.1965 28.5645 30.3846 28.9407C30.6802 29.5856 31.2579 29.908 32.1177 29.908C33.1657 29.908 33.8509 29.3034 34.1733 28.0943C34.4152 27.2344 34.5361 25.2997 34.5361 22.2902ZM32.0371 30.6335C28.6783 30.6335 26.139 29.7737 24.4193 28.054C22.6996 26.3342 21.8398 23.8756 21.8398 20.678C21.8398 17.4535 22.7534 14.9814 24.5806 13.2617C26.4346 11.5151 29.0276 10.6418 32.3596 10.6418C35.6915 10.6418 38.1771 11.448 39.8162 13.0602C41.4553 14.6455 42.2748 17.0773 42.2748 20.3555C42.2748 27.2075 38.8623 30.6335 32.0371 30.6335Z"
        fill="black"
      />
      <path
        d="M59.5647 8.94899L60.6933 8.26379C60.8545 7.43081 60.5321 7.01431 59.726 7.01431C58.5705 7.01431 57.9928 7.90104 57.9928 9.6745C57.9928 10.3731 58.0869 11.1792 58.275 12.0928C60.3171 13.4632 61.3382 15.2233 61.3382 17.3729C61.3382 19.4957 60.5993 21.1482 59.1214 22.3305C57.6435 23.5128 55.6416 24.104 53.1158 24.104C52.0679 24.104 50.9796 23.9965 49.851 23.7815C48.6687 24.5339 48.0776 25.0982 48.0776 25.4744C48.0776 25.8506 48.9374 26.0387 50.6572 26.0387H54.7683C60.868 26.0387 63.9178 28.2286 63.9178 32.6085C63.9178 34.9731 62.9907 36.8406 61.1367 38.211C59.3095 39.6083 56.4478 40.3069 52.5515 40.3069C45.9145 40.3069 42.596 38.8694 42.596 35.9942C42.596 34.4357 43.6305 33.3609 45.6995 32.7697L48.1179 33.858C47.9029 34.6372 47.7954 35.3762 47.7954 36.0748C47.7954 38.3857 49.5152 39.5411 52.9546 39.5411C55.0505 39.5411 56.6627 39.1515 57.7913 38.3722C58.9198 37.593 59.4841 36.6257 59.4841 35.4702C59.4841 34.3148 59.1348 33.5355 58.4362 33.1325C57.7644 32.7563 56.4075 32.5682 54.3653 32.5682H50.4556C48.2791 32.5682 46.7206 32.2055 45.7802 31.48C44.8397 30.7544 44.3695 29.8677 44.3695 28.8198C44.3695 27.7449 44.7053 26.8582 45.3771 26.1596C46.0489 25.4341 47.2446 24.5473 48.9643 23.4994C45.8473 22.6127 44.2888 20.5705 44.2888 17.3729C44.2888 15.3576 45.0143 13.732 46.4654 12.4959C47.9164 11.2599 50.0929 10.6418 52.9949 10.6418C54.7415 10.6418 56.2328 10.9777 57.4688 11.6495C57.3076 10.924 57.227 10.2656 57.227 9.6745C57.227 8.16975 57.6301 7.08149 58.4362 6.40973C59.2423 5.73796 60.1425 5.40208 61.1367 5.40208C62.1309 5.40208 62.9236 5.67078 63.5147 6.2082C64.1327 6.71874 64.4417 7.43081 64.4417 8.34441C64.4417 9.25801 64.1999 9.9432 63.7162 10.4C63.2326 10.8299 62.6414 11.0449 61.9428 11.0449C61.271 11.0449 60.7067 10.8702 60.2499 10.5209C59.82 10.1447 59.5916 9.62076 59.5647 8.94899ZM51.0199 16.4862V18.6627C51.0199 20.463 51.1677 21.6856 51.4633 22.3305C51.7857 22.9754 52.256 23.2979 52.874 23.2979C53.5189 23.2979 53.9757 22.9889 54.2444 22.3708C54.5399 21.7259 54.6877 20.4227 54.6877 18.4612V16.4862C54.6877 14.3903 54.5534 13.0199 54.2847 12.375C54.016 11.7032 53.5592 11.3673 52.9143 11.3673C52.2963 11.3673 51.826 11.7167 51.5036 12.4153C51.1811 13.0871 51.0199 14.444 51.0199 16.4862Z"
        fill="black"
      />
      <path
        d="M79.172 19.3882C79.172 16.6205 79.0376 14.7665 78.7689 13.826C78.5002 12.8587 77.9762 12.375 77.197 12.375C76.4177 12.375 75.7191 12.8587 75.1011 13.826C74.483 14.7933 74.174 16.1234 74.174 17.8163V25.3132C74.174 26.4686 74.4024 27.4494 74.8592 28.2555C75.3429 29.0616 76.0147 29.4647 76.8745 29.4647C77.7612 29.4647 78.3658 28.8735 78.6883 27.6912C79.0107 26.5089 79.172 24.4399 79.172 21.4841V19.3882ZM74.174 0.00109863V14.1081C75.1951 11.7973 76.9417 10.6418 79.4138 10.6418C84.4386 10.6418 86.951 13.9872 86.951 20.678C86.951 24.0905 86.2523 26.6029 84.8551 28.2152C83.4847 29.8274 81.4156 30.6335 78.648 30.6335C77.2507 30.6335 76.1759 30.4186 75.4235 29.9886C74.698 29.5587 74.2009 28.8466 73.9322 27.8524L73.6501 30.2305H64.4603V29.505H66.6771V0.726604H64.4603V0.00109863H74.174Z"
        fill="black"
      />
      <path
        d="M98.7562 30.6335C95.2899 30.6335 92.6834 29.7468 90.9368 27.9733C89.2171 26.173 88.3573 23.6875 88.3573 20.5168C88.3573 17.3192 89.3246 14.874 91.2593 13.1811C93.2208 11.4883 95.7064 10.6418 98.7159 10.6418C104.815 10.6418 107.744 13.7051 107.503 19.8316H96.1363V21.4035C96.1363 24.0368 96.4722 26.0252 97.1439 27.3688C97.8157 28.7123 98.9846 29.3841 100.651 29.3841C103.768 29.3841 105.81 27.7181 106.777 24.3861L107.503 24.507C106.992 26.4417 106.065 27.9465 104.721 29.0213C103.405 30.0961 101.416 30.6335 98.7562 30.6335ZM96.1766 19.0254H100.328V17.0505C100.328 14.874 100.194 13.3961 99.925 12.6168C99.6832 11.8107 99.1727 11.4076 98.3934 11.4076C97.641 11.4076 97.0768 11.8376 96.7006 12.6974C96.3513 13.5304 96.1766 14.9814 96.1766 17.0505V19.0254Z"
        fill="black"
      />
      <path
        d="M109.019 11.0449H118.733V14.753C119.163 13.517 119.821 12.5228 120.708 11.7704C121.594 11.018 122.938 10.6418 124.738 10.6418C128.903 10.6418 130.986 12.8855 130.986 17.3729V29.505H133.243V30.2305H121.836V29.505H123.489V16.4056C123.489 14.7933 123.381 13.7588 123.166 13.302C122.951 12.8184 122.562 12.5765 121.998 12.5765C121.138 12.5765 120.372 13.1408 119.7 14.2694C119.055 15.3979 118.733 16.7683 118.733 18.3806V29.505H120.466V30.2305H109.019V29.505H111.236V11.7704H109.019V11.0449Z"
        fill="black"
      />
      <path
        d="M141.957 21.8872C141.957 24.7086 142.105 26.5895 142.401 27.53C142.696 28.4436 143.234 28.9004 144.013 28.9004C144.819 28.9004 145.504 28.5511 146.069 27.8524C146.66 27.1538 146.955 26.1193 146.955 24.7489V15.9622C146.955 14.8068 146.727 13.826 146.27 13.0199C145.813 12.2138 145.142 11.8107 144.255 11.8107C143.368 11.8107 142.764 12.4019 142.441 13.5842C142.119 14.7665 141.957 16.8355 141.957 19.7913V21.8872ZM147.479 30.2305L147.036 27.4091C146.122 29.5587 144.268 30.6335 141.474 30.6335C139.163 30.6335 137.363 29.8005 136.073 28.1346C134.81 26.4686 134.178 23.9831 134.178 20.678C134.178 13.9872 136.839 10.6418 142.159 10.6418C144.524 10.6418 146.082 11.3002 146.834 12.6168V0.726604H144.376V0.00109863H154.452V29.505H156.427V30.2305H147.479Z"
        fill="black"
      />
      <path
        d="M168.071 30.6335C164.605 30.6335 161.998 29.7468 160.252 27.9733C158.532 26.173 157.672 23.6875 157.672 20.5168C157.672 17.3192 158.64 14.874 160.574 13.1811C162.536 11.4883 165.021 10.6418 168.031 10.6418C174.13 10.6418 177.059 13.7051 176.818 19.8316H165.451V21.4035C165.451 24.0368 165.787 26.0252 166.459 27.3688C167.131 28.7123 168.3 29.3841 169.966 29.3841C173.083 29.3841 175.125 27.7181 176.092 24.3861L176.818 24.507C176.307 26.4417 175.38 27.9465 174.036 29.0213C172.72 30.0961 170.731 30.6335 168.071 30.6335ZM165.492 19.0254H169.643V17.0505C169.643 14.874 169.509 13.3961 169.24 12.6168C168.998 11.8107 168.488 11.4076 167.708 11.4076C166.956 11.4076 166.392 11.8376 166.016 12.6974C165.666 13.5304 165.492 14.9814 165.492 17.0505V19.0254Z"
        fill="black"
      />
      <path
        d="M191.716 12.1735C190.721 12.1735 189.848 12.8184 189.096 14.1081C188.343 15.3979 187.967 16.9295 187.967 18.703V29.505H190.829V30.2305H178.253V29.505H180.47V11.7704H178.253V11.0449H187.967V14.9143C188.316 13.5439 188.988 12.4959 189.982 11.7704C190.977 11.018 192.105 10.6418 193.368 10.6418C194.631 10.6418 195.652 11.0046 196.431 11.7301C197.237 12.4287 197.641 13.4364 197.641 14.753C197.641 16.0428 197.345 17.037 196.754 17.7357C196.163 18.4343 195.249 18.7836 194.013 18.7836C192.804 18.7836 191.904 18.3806 191.312 17.5744C190.748 16.7683 190.681 15.6532 191.111 14.2291H192.562C193.234 12.8587 192.952 12.1735 191.716 12.1735Z"
        fill="black"
      />
    </svg>
  );
};

export const Hamburger = ({ className = defaultClassName, ariaLabel = "" }) => {
  return (
    <svg
      aria-label={ariaLabel}
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      width="36"
      height="28"
      viewBox="0 0 36 28"
      fill="none"
    >
      <path
        d="M2 26H34M2 2H34H2ZM2 14H34H2Z"
        stroke="currentColor"
        strokeWidth="4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
};

export const LinkedIn: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      aria-labelledby="linkedin"
      className={className}
      fill="#0A66C2"
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      role="img"
      viewBox="0 0 24 24"
    >
      <title id="linkedin">linkedin</title>
      <path d="M0 0v24h24v-24h-24zm8 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.397-2.586 7-2.777 7 2.476v6.759z" />
    </svg>
  );
};

export const LinkedInRounded: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 25"
      fill="none"
    >
      <path
        d="M0 12.3406C0 5.71316 5.37258 0.340576 12 0.340576C18.6274 0.340576 24 5.71316 24 12.3406C24 18.968 18.6274 24.3406 12 24.3406C5.37258 24.3406 0 18.968 0 12.3406Z"
        fill="currentcolor"
      />
      <path d="M8.48106 10.2793H5.7616V18.4502H8.48106V10.2793Z" fill="white" />
      <path
        d="M8.65893 7.75192C8.64128 6.95078 8.06838 6.34058 7.13806 6.34058C6.20775 6.34058 5.59955 6.95078 5.59955 7.75192C5.59955 8.53648 6.18978 9.16425 7.10276 9.16425H7.12014C8.06838 9.16425 8.65893 8.53648 8.65893 7.75192Z"
        fill="white"
      />
      <path
        d="M18.2865 13.7657C18.2865 11.256 16.9449 10.0879 15.1554 10.0879C13.7115 10.0879 13.0651 10.881 12.7042 11.4373V10.28H9.98438C10.0202 11.0467 9.98438 18.4508 9.98438 18.4508H12.7042V13.8876C12.7042 13.6434 12.7218 13.3997 12.7937 13.2249C12.9903 12.7371 13.4378 12.2319 14.1891 12.2319C15.1735 12.2319 15.5671 12.9812 15.5671 14.0792V18.4506H18.2864L18.2865 13.7657Z"
        fill="white"
      />
    </svg>
  );
};

export const Logo: Icon = ({ className = defaultClassName, ariaLabel }) => {
  return (
    <svg
      role="img"
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 69 82"
      fill="none"
      aria-label={ariaLabel}
    >
      <path d="M14.8699 0L0 50.3649L14.8699 81.8078L30.513 50.3649L14.8699 0Z" fill="#FE346E" />
      <path
        d="M26.9487 66.578L34.1498 81.8049L49.3923 51.1672L34.1498 0L26.9679 25.3624L34.8416 50.7131L26.9487 66.578Z"
        fill="#FF7315"
      />
      <path
        d="M46.2284 66.5781L53.4294 81.8049L68.6718 51.1672L53.4294 0L46.084 25.9398L53.7101 51.5397L46.2284 66.5781Z"
        fill="#7E0CF5"
      />
    </svg>
  );
};

export const Mail: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 25"
      fill="none"
    >
      <path
        d="M12 24.3406C5.37258 24.3406 0 18.968 0 12.3406C0 5.71316 5.37258 0.340576 12 0.340576C18.6274 0.340576 24 5.71316 24 12.3406C24 18.968 18.6274 24.3406 12 24.3406Z"
        fill="currentcolor"
      />
      <path
        d="M12.1677 11.667C13.1502 11.667 17.9277 8.98053 17.9277 8.98053L17.9353 8.50053C17.9353 7.97061 17.5053 7.54053 16.9739 7.54053H7.36141C6.83053 7.54053 6.40045 7.97061 6.40045 8.50053V8.92821C6.40045 8.92821 11.2302 11.667 12.1677 11.667Z"
        fill="white"
      />
      <path
        d="M12.1677 12.9872C11.2302 12.9872 6.40765 10.4207 6.40813 10.4207L6.40045 16.1807C6.40045 16.7106 6.83101 17.1407 7.36141 17.1407H16.9739C17.5053 17.1407 17.9353 16.7106 17.9353 16.1807L17.9277 10.4207C17.9277 10.4207 13.1953 12.9872 12.1677 12.9872Z"
        fill="white"
      />
    </svg>
  );
};

export const Telegram: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 25"
      fill="none"
    >
      <path
        d="M12 24.3406C5.37258 24.3406 0 18.968 0 12.3406C0 5.71316 5.37258 0.340576 12 0.340576C18.6274 0.340576 24 5.71316 24 12.3406C24 18.968 18.6274 24.3406 12 24.3406Z"
        fill="currentcolor"
      />
      <path
        d="M10.0027 14.7817L9.7985 17.8406C10.0985 17.8406 10.2311 17.7034 10.3985 17.5406L11.8399 16.139L14.8385 18.3545C15.3904 18.659 15.7886 18.5013 15.9261 17.8421L17.8946 8.56582C18.0961 7.7578 17.5866 7.39132 17.0587 7.631L5.49966 12.0881C4.71065 12.4046 4.71525 12.8448 5.35584 13.0409L8.32214 13.9667L15.1894 9.63423C15.5136 9.43764 15.8112 9.54333 15.567 9.76007L10.0025 14.7816L10.0027 14.7817Z"
        fill="white"
      />
    </svg>
  );
};

export const Twitter: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      className={className}
      width="24"
      height="24"
      viewBox="0 0 1200 1227"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M714.163 519.284L1160.89 0H1055.03L667.137 450.887L357.328 0H0L468.492 681.821L0 1226.37H105.866L515.491 750.218L842.672 1226.37H1200L714.137 519.284H714.163ZM569.165 687.828L521.697 619.934L144.011 79.6944H306.615L611.412 515.685L658.88 583.579L1055.08 1150.3H892.476L569.165 687.854V687.828Z"
        fill="black"
      />
    </svg>
  );
};

export const TwitterRounded: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      className={className}
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle cx="12" cy="12" r="11" fill="currentColor" />
      <path
        d="M13.1416 11.0812L17.6089 6H16.5503L12.6714 10.4119L9.57328 6H6L10.6849 12.6716L6 18H7.05866L11.1549 13.3409L14.4267 18H18L13.1414 11.0812H13.1416ZM11.6916 12.7304L11.217 12.066L7.44011 6.77981H9.06615L12.1141 11.046L12.5888 11.7103L16.5508 17.2557H14.9248L11.6916 12.7306V12.7304Z"
        fill="white"
      />
    </svg>
  );
};

export const XClose: Icon = ({ className = defaultClassName, ariaLabel }) => {
  return (
    <svg
      className={className}
      aria-label={ariaLabel}
      xmlns="http://www.w3.org/2000/svg"
      width="48"
      height="48"
      viewBox="0 0 40 40"
      fill="none"
    >
      <path
        d="M10 10L38 38"
        stroke="#6B7280"
        strokeWidth="4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M10 38L38 10"
        stroke="#6B7280"
        strokeWidth="4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
};

export const Warning: Icon = ({ className = defaultClassName }) => {
  return (
    <svg
      className={className}
      width="20"
      height="18"
      viewBox="0 0 20 18"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M9.99992 6.99999V8.99999M9.99992 13H10.0099M3.07192 17H16.9279C18.4679 17 19.4299 15.333 18.6599 14L11.7319 1.99999C10.9619 0.666994 9.03792 0.666994 8.26792 1.99999L1.33992 14C0.569924 15.333 1.53192 17 3.07192 17Z"
        stroke="#9CA3AF"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
};

export const GitHub = ({ className = "w-6 h-6" }) => {
  return (
    <svg className={className} viewBox="0 0 98 96" xmlns="http://www.w3.org/2000/svg">
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M48.854 0C21.839 0 0 22 0 49.217c0 21.756 13.993 40.172 33.405 46.69 2.427.49 3.316-1.059 3.316-2.362 0-1.141-.08-5.052-.08-9.127-13.59 2.934-16.42-5.867-16.42-5.867-2.184-5.704-5.42-7.17-5.42-7.17-4.448-3.015.324-3.015.324-3.015 4.934.326 7.523 5.052 7.523 5.052 4.367 7.496 11.404 5.378 14.235 4.074.404-3.178 1.699-5.378 3.074-6.6-10.839-1.141-22.243-5.378-22.243-24.283 0-5.378 1.94-9.778 5.014-13.2-.485-1.222-2.184-6.275.486-13.038 0 0 4.125-1.304 13.426 5.052a46.97 46.97 0 0 1 12.214-1.63c4.125 0 8.33.571 12.213 1.63 9.302-6.356 13.427-5.052 13.427-5.052 2.67 6.763.97 11.816.485 13.038 3.155 3.422 5.015 7.822 5.015 13.2 0 18.905-11.404 23.06-22.324 24.283 1.78 1.548 3.316 4.481 3.316 9.126 0 6.6-.08 11.897-.08 13.526 0 1.304.89 2.853 3.316 2.364 19.412-6.52 33.405-24.935 33.405-46.691C97.707 22 75.788 0 48.854 0z"
        fill="currentColor"
      />
    </svg>
  );
};