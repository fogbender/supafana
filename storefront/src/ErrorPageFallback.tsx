import React from "react";

export const ErrorPageFallback: React.FC<{
  error?: Error;
  resetErrorBoundary: () => void;
}> = ({ error }) => {
  return (
    <div className="bg-white dark:bg-brand-dark-bg py-4 px-8 text-black dark:text-white h-full">
      <h1 className="text-2xl font-extrabold leading-8 text-gray-900 sm:text-3xl sm:leading-9">
        Oops... Sorry!
      </h1>
      <p className="my-2">Looks like we’ve stumbled upon an error:</p>
      <div className="my-4 text-red-600">
        {error && <pre className="text-sm">{error.message}</pre>}
      </div>
      <h1 className="text-xl font-bold leading-7 text-gray-900 sm:text-2xl sm:leading-8">
        You can always contact us
      </h1>
      <p className="my-2">
        <a className="cursor-pointer underline" href="mailto:support@fogbender.com">
          support@fogbender.com
        </a>
      </p>
      <p className="my-2">
        <a className="cursor-pointer underline" href="tel:+14152903979">
          +1-415-290-3979
        </a>
      </p>
      <p className="my-2">
        720 Peralta St
        <br />
        Oakland, CA
        <br />
        94607
      </p>
    </div>
  );
};
